//
//  AnalyzerApp.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation
import SwiftParser
import SwiftSyntax

/// Command-line entry point that coordinates scanning, analysis, reporting, and AI suggestions.
@main
struct AnalyzerApp {
    private enum OutputFormat {
        case console
        case json
        case xcode
        case sarif

        var isMachineReadable: Bool {
            self == .json || self == .sarif
        }
    }

    private struct CLIOptions {
        let outputFormat: OutputFormat
        let failOnWarning: Bool
        let failOnCritical: Bool
        let strict: Bool
        let shouldShowHelp: Bool
        let inputPath: String

        var isJsonMode: Bool { outputFormat == .json }
        var isXcodeMode: Bool { outputFormat == .xcode }
        var isSarifMode: Bool { outputFormat == .sarif }
        var isMachineReadable: Bool { outputFormat.isMachineReadable }
    }

    /// Runs the full analyzer lifecycle:
    /// - validates CLI input
    /// - discovers target Swift files
    /// - parses/visits syntax
    /// - evaluates rule violations
    /// - optionally enriches results with AI suggestions
    /// - emits per-file and summary reports
    static func main() async {
        let options = parseCLIArguments()
        if options.shouldShowHelp {
            print(usageText)
            return
        }

        let fullPath = URL(fileURLWithPath: options.inputPath).standardized.path
        
        var isDirectory: ObjCBool = false
        
        guard FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory) else {
            emitError("Path does not exist", isJsonMode: options.isJsonMode)
            exit(1)
        }

        if let validationError = InputPathValidator.singleFileExtensionError(
            for: fullPath,
            isDirectory: isDirectory.boolValue
        ) {
            emitError(validationError, isJsonMode: options.isJsonMode)
            exit(1)
        }
        
        // 2. Determine root for config
        let rootPath = isDirectory.boolValue
            ? fullPath
            : URL(fileURLWithPath: fullPath).deletingLastPathComponent().path

        EnvironmentFileLoader.apply(fromRootPath: rootPath, isJsonMode: options.isMachineReadable)
        
        let config = ConfigLoader.load(from: rootPath)
        
        // 3. Scan files
        let filePaths: [String]
        
        if isDirectory.boolValue {
            if options.outputFormat == .console { print("📂 Scanning folder: \(fullPath)") }
            filePaths = FileScanner.getSwiftFiles(in: fullPath, ignoring: config.ignoreDirectories)
        } else {
            filePaths = [fullPath]
        }
        
        guard !filePaths.isEmpty else {
            if options.outputFormat == .console { print("⚠️ No Swift files found.") }
            exit(0)
        }
        
        if options.outputFormat == .console { print("📊 Found \(filePaths.count) Swift files\n") }
        
        // 4. Build rules from config
        var rules: [Rule] = []
        
        if config.rules?.largeClass?.enabled == true {
            let threshold = config.rules?.largeClass?.threshold ?? RuleConstants.largeClassThreshold
            rules.append(LargeClassRule(threshold: threshold))
        }
        
        if config.rules?.highMethodDensity?.enabled == true {
            let threshold = config.rules?.highMethodDensity?.threshold ?? RuleConstants.tooManyMethodThreshold
            rules.append(HighMethodDensityRule(threshold: threshold))
        }
        
        if config.rules?.godObject?.enabled == true {
            rules.append(GodObjectRule())
        }

        if config.rules?.dataHeavyClass?.enabled == true {
            let threshold = config.rules?.dataHeavyClass?.threshold ?? RuleConstants.dataHeavyClassThreshold
            rules.append(DataHeavyClassRule(threshold: threshold))
        }
        
        if config.rules?.viewModelUIKit?.enabled == true {
            rules.append(ViewModelUIKitRule())
        }

        if config.rules?.modelServiceUIKit?.enabled == true {
            rules.append(ModelServiceUIKitRule())
        }
        
        let engine = RuleEngine(rules: rules)
        let reporter: Reporter = options.isXcodeMode ? XcodeReporter(rootPath: rootPath) : ConsoleReporter()
        let aiConfiguration = AIConfiguration.fromEnvironment()
        
        var summary = AnalysisSummary()
        summary.totalFiles = filePaths.count
        
        var fileIssueMap: [String: [Issue]] = [:]
        var allIssueReports: [IssueReport] = []
        var hasProcessingErrors = false
        
        // 5. Process files
        for filePath in filePaths {
            do {
                let source = try String(contentsOf: URL(fileURLWithPath: filePath), encoding: .utf8)
                let sourceFile = Parser.parse(source: source)
                
                // Pre-pass: extract top-level import names from the syntax tree.
                // Doing this separately avoids traversal-ordering issues with the
                // SyntaxVisitor approach on SwiftSyntax 508.
                let fileImports: [String] = sourceFile.statements.compactMap { item in
                    if case .decl(let decl) = item.item,
                       let importDecl = decl.as(ImportDeclSyntax.self) {
                        return importDecl.path.tokens(viewMode: .fixedUp)
                            .map { $0.text }
                            .joined()
                    }
                    return nil
                }
                


                let visitor = ClassVisitor(viewMode: .all, fileImports: fileImports)
                visitor.walk(sourceFile)
                
                let displayPath = relativePath(for: filePath, rootPath: rootPath)
                
                let suppressedRules = SuppressionParser.suppressedRuleNames(in: source)
                let issues = SuppressionParser.filter(
                    engine.analyze(visitor.classes),
                    suppressedRuleNames: suppressedRules
                )
                fileIssueMap[displayPath] = issues
                
                summary.totalClasses += visitor.classes.count
                summary.addIssues(issues)
                
                if options.isMachineReadable {
                    // Map canonical rule-engine output to machine-readable reports.
                    for issue in issues {
                        allIssueReports.append(IssueReport(
                            rule: issue.ruleName,
                            severity: issue.severity.rawValue,
                            message: issue.message,
                            file: displayPath,
                            line: issue.line,
                            typeName: inferTypeName(for: issue, classes: visitor.classes)
                        ))
                    }
                } else {
                    // Use reporter for per-file results
                    reporter.report(file: displayPath, classes: visitor.classes, issues: issues)

                    if let suggester = buildAISuggester(configuration: aiConfiguration) {
                        let suggestions = await suggester.generateSuggestions(
                            issues: issues,
                            classes: visitor.classes,
                            sourceCode: source
                        )
                        if options.isXcodeMode {
                            reportAISuggestionsForXcode(
                                suggestions,
                                issues: issues,
                                filePath: filePath
                            )
                        } else {
                            reportAISuggestions(suggestions, file: displayPath)
                        }
                    }
                }
                
            } catch {
                hasProcessingErrors = true
                emitError("Error reading file: \(filePath)\n   \(error)", isJsonMode: options.isJsonMode)
            }
        }
        
        // 6. Final summary
        if options.isJsonMode {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let data = try? encoder.encode(allIssueReports), let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else if options.isSarifMode {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let report = SarifReport.make(from: allIssueReports)
            if let data = try? encoder.encode(report), let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            reporter.reportSummary(summary, fileIssueMap: fileIssueMap)
        }

        let exitCode = finalExitCode(
            summary: summary,
            hasProcessingErrors: hasProcessingErrors,
            options: options
        )
        if exitCode != 0 {
            exit(exitCode)
        }
    }

    /// Parses command-line arguments and validates required positional input.
    private static func parseCLIArguments() -> CLIOptions {
        let arguments = Array(CommandLine.arguments.dropFirst())
        var outputFormat: OutputFormat = .console
        let strict = arguments.contains("--strict")
        let failOnWarning = arguments.contains("--fail-on-warning")
        let failOnCritical = arguments.contains("--fail-on-critical")
        let shouldShowHelp = arguments.contains("--help") || arguments.contains("-h")
        var positional: [String] = []

        if shouldShowHelp {
            return CLIOptions(
                outputFormat: outputFormat,
                failOnWarning: failOnWarning,
                failOnCritical: failOnCritical,
                strict: strict,
                shouldShowHelp: true,
                inputPath: ""
            )
        }

        var index = 0
        while index < arguments.count {
            let argument = arguments[index]

            switch argument {
            case "--json":
                outputFormat = .json
            case "--xcode":
                outputFormat = .xcode
            case "--format":
                guard index + 1 < arguments.count else {
                    emitError("Missing value for --format", isJsonMode: false)
                    exit(1)
                }
                outputFormat = outputFormatValue(arguments[index + 1])
                index += 1
            case "--strict", "--fail-on-warning", "--fail-on-critical":
                break
            default:
                if !argument.hasPrefix("--") {
                    positional.append(argument)
                }
            }

            index += 1
        }

        let inputPath = positional.first ?? "sample.swift"
        return CLIOptions(
            outputFormat: outputFormat,
            failOnWarning: failOnWarning,
            failOnCritical: failOnCritical,
            strict: strict,
            shouldShowHelp: false,
            inputPath: inputPath
        )
    }

    private static let usageText = """
    Usage:
      aianalyzer <path> [options]

    Arguments:
      <path>                    Swift file or project folder to analyze.

    Options:
      --format <console|json|xcode|sarif>
                                Choose output format. Defaults to console.
      --json                    Shortcut for --format json.
      --xcode                   Shortcut for --format xcode.
      --fail-on-critical        Exit 1 when critical issues are found.
      --fail-on-warning         Exit 1 when warning or critical issues are found.
      --strict                  Exit 1 when any issue is found.
      -h, --help                Show this help message.

    Examples:
      aianalyzer Sources
      aianalyzer MyApp --format sarif > aianalyzer.sarif
      aianalyzer MyApp --format xcode --fail-on-critical
    """

    private static func outputFormatValue(_ rawValue: String) -> OutputFormat {
        switch rawValue.lowercased() {
        case "console":
            return .console
        case "json":
            return .json
        case "xcode":
            return .xcode
        case "sarif":
            return .sarif
        default:
            emitError("Unsupported --format value: \(rawValue)", isJsonMode: false)
            exit(1)
        }
    }

    /// Emits errors to stderr in JSON mode to avoid corrupting machine-readable stdout.
    private static func emitError(_ message: String, isJsonMode: Bool) {
        if isJsonMode {
            fputs("ERROR: \(message)\n", stderr)
        } else {
            print("❌ \(message)")
        }
    }

    /// Determines whether the process should fail for CI / script quality gates.
    ///
    /// Exit code `1` is intentionally used for both processing errors and failed quality gates
    /// so shell scripts and CI systems can treat the run as unsuccessful without extra mapping.
    private static func finalExitCode(
        summary: AnalysisSummary,
        hasProcessingErrors: Bool,
        options: CLIOptions
    ) -> Int32 {
        if hasProcessingErrors {
            return 1
        }

        if options.strict && summary.issueCounts.total > 0 {
            return 1
        }

        if options.failOnWarning &&
            (summary.issueCounts.warnings > 0 || summary.issueCounts.criticals > 0) {
            return 1
        }

        if options.failOnCritical && summary.issueCounts.criticals > 0 {
            return 1
        }

        return 0
    }

    /// Best-effort mapping of an issue to a type name for JSON output.
    private static func inferTypeName(for issue: Issue, classes: [ClassInfo]) -> String {
        for classInfo in classes where issue.message.contains(classInfo.name) {
            return classInfo.name
        }
        return classes.first?.name ?? "UnknownType"
    }

    /// Produces a stable path for reports. Directory scans use paths relative to the scan root,
    /// while single-file scans fall back to the file name.
    private static func relativePath(for filePath: String, rootPath: String) -> String {
        let fileURL = URL(fileURLWithPath: filePath).standardizedFileURL
        let rootURL = URL(fileURLWithPath: rootPath).standardizedFileURL

        let fileComponents = fileURL.pathComponents
        let rootComponents = rootURL.pathComponents

        guard fileComponents.starts(with: rootComponents) else {
            return fileURL.lastPathComponent
        }

        let relativeComponents = fileComponents.dropFirst(rootComponents.count)
        return relativeComponents.isEmpty
            ? fileURL.lastPathComponent
            : relativeComponents.joined(separator: "/")
    }

    /// Builds an `AISuggester` from runtime configuration and provider strategy.
    ///
    /// Provider selection rules:
    /// - `gemini`: requires `GEMINI_API_KEY`.
    /// - `local`: Core ML + heuristics (`AI_LOCAL_MODEL_PATH` optional).
    /// - `ollama`: local Ollama OpenAI-compatible API (`OLLAMA_MODEL`, `OLLAMA_ENDPOINT`).
    /// - `hybrid`: Ollama-first; escalates to Gemini when local confidence is low or Ollama fails; heuristic Core ML fallback as last resort.
    ///
    /// - Parameter configuration: Resolved AI runtime configuration.
    /// - Returns: Configured suggester or `nil` when AI is disabled/misconfigured.
    private static func buildAISuggester(configuration: AIConfiguration) -> AISuggester? {
        guard configuration.enabled else {
            return nil
        }

        let provider: AIProvider

        switch configuration.serviceConfig.providerType {
        case .gemini:
            guard configuration.serviceConfig.cloudOptIn else {
                print("⚠️ AI_PROVIDER=gemini requires AI_CLOUD_OPT_IN=true because source snippets may leave this machine.")
                return nil
            }

            guard let apiKey = configuration.serviceConfig.apiKey, !apiKey.isEmpty else {
                print("⚠️ AI is set to \'gemini\' but GEMINI_API_KEY is missing.")
                return nil
            }
            provider = GeminiProvider(apiKey: apiKey, model: configuration.serviceConfig.model)

        case .ollama:
            provider = OllamaProvider(endpoint: configuration.serviceConfig.ollamaEndpoint, modelName: configuration.serviceConfig.ollamaModel)

        case .local:
            if let warning = Self.localProviderCoreMLDiagnostics(configuration: configuration) {
                print(warning)
            }
            provider = LocalLLMProvider(modelPath: configuration.localModelConfig.localModelPath, modelName: configuration.localModelConfig.localModelName)

        case .hybrid:
            let cloud: AIProvider?
            if configuration.serviceConfig.cloudOptIn,
               let apiKey = configuration.serviceConfig.apiKey,
               !apiKey.isEmpty {
                cloud = GeminiProvider(apiKey: apiKey, model: configuration.serviceConfig.model)
            } else {
                cloud = nil
                if configuration.serviceConfig.cloudOptIn {
                    print("ℹ️ Hybrid mode cloud escalation requested, but GEMINI_API_KEY is missing. Using local fallback path.")
                } else {
                    print("ℹ️ Hybrid mode running local-only. Set AI_CLOUD_OPT_IN=true to allow Gemini escalation.")
                }
            }

            // Prefer Ollama as the local tier in Hybrid mode
            let localPreferred = OllamaProvider(endpoint: configuration.serviceConfig.ollamaEndpoint, modelName: configuration.serviceConfig.ollamaModel)
            let localFallback = LocalLLMProvider(modelPath: nil, modelName: configuration.localModelConfig.localModelName, failIfStub: false)

            provider = HybridAIProvider(
                localPreferred: localPreferred,
                localFallback: localFallback,
                cloud: cloud,
                preferLocal: true
            )
        }


        return AISuggester(
            provider: provider,
            maxSuggestions: configuration.maxSuggestions,
            snippetLineLimit: configuration.snippetLineLimit
        )
    }

    /// Explains why `AI_PROVIDER=local` may still show heuristic output (Core ML vs Ollama).
    private static func localProviderCoreMLDiagnostics(configuration: AIConfiguration) -> String? {
        guard let path = configuration.localModelConfig.localModelPath else {
            return """
            ⚠️ AI_PROVIDER=local uses Core ML only (`LocalLLMProvider`), not Ollama.
               `AI_LOCAL_MODEL` is only a label; without a valid `AI_LOCAL_MODEL_PATH` (.mlmodelc), you get rule-based heuristics.
               For Qwen via Ollama: set AI_PROVIDER=ollama and OLLAMA_MODEL (e.g. qwen2.5-coder:7b).
            """
        }
        if !FileManager.default.fileExists(atPath: path) {
            return """
            ⚠️ AI_LOCAL_MODEL_PATH not found: \(path)
               Core ML inference will fail; output falls back to heuristics.
               Point to a real .mlmodelc bundle, or use AI_PROVIDER=ollama for your Qwen model.
            """
        }
        return nil
    }

    /// Prints AI suggestions for a single analyzed file in a readable terminal section.
    ///
    /// Output style can be adjusted through environment flags:
    /// - `AI_VERBOSE`
    /// - `AI_TYPEWRITER_MS`
    ///
    /// - Parameters:
    ///   - suggestions: Suggestions generated for the file.
    ///   - file: File name used as report heading.
    private static func reportAISuggestions(_ suggestions: [AISuggestion], file: String) {
        guard !suggestions.isEmpty else {
            return
        }

        let verboseAI = (ProcessInfo.processInfo.environment["AI_VERBOSE"] ?? "false").lowercased() == "true"
        let typewriterDelayMs = Int(ProcessInfo.processInfo.environment["AI_TYPEWRITER_MS"] ?? "") ?? 8
        print("🤖 AI Suggestions for \(file)")
        print(String(repeating: "-", count: 40))
        for suggestion in suggestions {
            let formatted = AISuggestionFormatter.format(suggestion, verbose: verboseAI)
            printWithTypewriterEffect(formatted, delayMs: typewriterDelayMs)
            print(String(repeating: "-", count: 40))
        }
    }

    /// Emits AI suggestions as Xcode-compatible notes so they show up in Issues.
    ///
    /// Format: `<absolute-path>:<line>: note: [AIAnalyzer][AI] ...`
    /// This keeps static findings as warning/error while surfacing AI guidance alongside them.
    private static func reportAISuggestionsForXcode(
        _ suggestions: [AISuggestion],
        issues: [Issue],
        filePath: String
    ) {
        guard !suggestions.isEmpty else {
            return
        }

        for suggestion in suggestions {
            let matchedIssueLine = issues.first(where: { issue in
                issue.ruleName == suggestion.metadata.ruleName &&
                issue.message.contains(suggestion.metadata.typeName)
            })?.line ?? 1

            let diagnosis = suggestion.content.diagnosis
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let safeDiagnosis = diagnosis.isEmpty ? "AI suggestion generated." : diagnosis
            let note = "[AIAnalyzer][AI][\(suggestion.metadata.ruleName)] \(safeDiagnosis)"
            print("\(filePath):\(matchedIssueLine): note: \(note)")
        }
    }

    /// Renders text with a typewriter effect to improve readability in CLI output.
    /// - Parameters:
    ///   - text: Content to print.
    ///   - delayMs: Delay in milliseconds between characters.
    private static func printWithTypewriterEffect(_ text: String, delayMs: Int) {
        let safeDelay = max(0, delayMs)
        for character in text {
            print(String(character), terminator: "")
            fflush(stdout)
            if safeDelay > 0 {
                Thread.sleep(forTimeInterval: Double(safeDelay) / 1000.0)
            }
        }
        print("")
    }
}

/// Loads project-level environment values from `.aianalyzer.env`.
///
/// Walks upward from the scan root so CLI runs from `tools/AIAnalyzer` still pick up the repo-level
/// file. If multiple ancestor directories contain this file, only the **outermost** (closest to the
/// filesystem root) is applied so there is a single source of truth per clone.
private enum EnvironmentFileLoader {
    private static let fileName = ".aianalyzer.env"

    /// Nearest to the scan root first; outermost (repository-level) last.
    private static func envFileChain(fromRootPath rootPath: String) -> [URL] {
        var found: [URL] = []
        var current = URL(fileURLWithPath: rootPath).standardizedFileURL

        while true {
            let candidate = current.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: candidate.path) {
                found.append(candidate)
            }

            let parent = current.deletingLastPathComponent()
            if parent.path == current.path || current.path == "/" {
                break
            }
            current = parent
        }

        return found
    }

    static func apply(fromRootPath rootPath: String, isJsonMode: Bool) {
        let chain = envFileChain(fromRootPath: rootPath)
        guard let outermost = chain.last else {
            return
        }

        if chain.count > 1 {
            let ignored = chain.dropLast().map(\.path).joined(separator: ", ")
            emitWarning(
                "Multiple .aianalyzer.env files found; ignoring nested: \(ignored)",
                isJsonMode: isJsonMode
            )
        }

        guard let contents = try? String(contentsOf: outermost, encoding: .utf8) else {
            emitWarning(
                "Could not read \(outermost.path); continuing with shell environment variables.",
                isJsonMode: isJsonMode
            )
            return
        }

        let entries = parse(contents: contents)
        let keysFromFile = Set(entries.map(\.0))

        for (key, value) in entries {
            setenv(key, value, 1)
        }

        let providerLabel = getenvString("AI_PROVIDER") ?? "unset"
        let providerSource: String
        if keysFromFile.contains("AI_PROVIDER") {
            providerSource = "source: env file"
        } else if providerLabel != "unset" {
            providerSource = "source: inherited from environment (not set in this file)"
        } else {
            providerSource = "source: unset (AIConfiguration defaults to local when absent)"
        }

        emitWarning(
            "Loaded env from \(outermost.path) "
                + "(AI_PROVIDER=\(providerLabel); \(providerSource); envLogFmt=v2)",
            isJsonMode: isJsonMode
        )
    }

    private static func emitWarning(_ message: String, isJsonMode: Bool) {
        let formatted = "warning: [AIAnalyzer] \(message)\n"
        if isJsonMode {
            fputs(formatted, stderr)
        } else {
            print(formatted, terminator: "")
        }
    }

    private static func getenvString(_ name: String) -> String? {
        guard let ptr = getenv(name) else { return nil }
        return String(cString: ptr)
    }

    private static func parse(contents: String) -> [(String, String)] {
        var entries: [(String, String)] = []

        for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }

            guard let separatorIndex = line.firstIndex(of: "=") else {
                continue
            }

            let key = String(line[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
            var value = String(line[line.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespaces)

            // Support optional wrapping quotes for values with spaces.
            if value.count >= 2 {
                let startsWithDoubleQuote = value.hasPrefix("\"")
                let endsWithDoubleQuote = value.hasSuffix("\"")
                let startsWithSingleQuote = value.hasPrefix("'")
                let endsWithSingleQuote = value.hasSuffix("'")
                if (startsWithDoubleQuote && endsWithDoubleQuote) || (startsWithSingleQuote && endsWithSingleQuote) {
                    value.removeFirst()
                    value.removeLast()
                }
            }

            guard !key.isEmpty else {
                continue
            }

            entries.append((key, value))
        }

        return entries
    }
}
