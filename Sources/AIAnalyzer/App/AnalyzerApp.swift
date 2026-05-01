//
//  AnalyzerApp.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation
import SwiftParser

/// Command-line entry point that coordinates scanning, analysis, reporting, and AI suggestions.
@main
struct AnalyzerApp {
    /// Runs the full analyzer lifecycle:
    /// - validates CLI input
    /// - discovers target Swift files
    /// - parses/visits syntax
    /// - evaluates rule violations
    /// - optionally enriches results with AI suggestions
    /// - emits per-file and summary reports
    static func main() async {
        
        // 1. Validate input
        guard CommandLine.arguments.count > 1 else {
            print("Usage: swift run AIAnalyzer <file.swift | folder>")
            exit(1)
        }

        let inputPath = CommandLine.arguments[1]
        let fullPath = URL(fileURLWithPath: inputPath).standardized.path
        
        var isDirectory: ObjCBool = false
        
        guard FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory) else {
            print("❌ Path does not exist")
            exit(1)
        }

        if let validationError = InputPathValidator.singleFileExtensionError(
            for: fullPath,
            isDirectory: isDirectory.boolValue
        ) {
            print(validationError)
            exit(1)
        }
        
        // 2. Determine root for config
        let rootPath = isDirectory.boolValue
            ? fullPath
            : URL(fileURLWithPath: fullPath).deletingLastPathComponent().path
        
        let config = ConfigLoader.load(from: rootPath)
        
        // 3. Scan files
        let filePaths: [String]
        
        if isDirectory.boolValue {
            print("📂 Scanning folder: \(fullPath)")
            filePaths = FileScanner.getSwiftFiles(in: fullPath, ignoring: config.ignoreDirectories)
        } else {
            filePaths = [fullPath]
        }
        
        guard !filePaths.isEmpty else {
            print("⚠️ No Swift files found.")
            exit(0)
        }
        
        print("📊 Found \(filePaths.count) Swift files\n")
        
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
        
        let engine = RuleEngine(rules: rules)
        let reporter: Reporter = ConsoleReporter()
        EnvironmentFileLoader.apply(fromRootPath: rootPath)
        let aiConfiguration = AIConfiguration.fromEnvironment()
        
        var summary = AnalysisSummary()
        summary.totalFiles = filePaths.count
        
        var fileIssueMap: [String: [Issue]] = [:]
        
        // 5. Process files
        for filePath in filePaths {
            do {
                let source = try String(contentsOf: URL(fileURLWithPath: filePath), encoding: .utf8)
                let sourceFile = Parser.parse(source: source)
                
                let visitor = ClassVisitor(viewMode: .all)
                visitor.walk(sourceFile)
                
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                
                let issues = engine.analyze(visitor.classes)
                fileIssueMap[fileName] = issues
                
                summary.totalClasses += visitor.classes.count
                summary.addIssues(issues)
                
                // Use reporter for per-file results
                reporter.report(file: fileName, classes: visitor.classes, issues: issues)

                if let suggester = buildAISuggester(configuration: aiConfiguration) {
                    let suggestions = await suggester.generateSuggestions(
                        issues: issues,
                        classes: visitor.classes,
                        sourceCode: source
                    )
                    reportAISuggestions(suggestions, file: fileName)
                }
                
            } catch {
                print("❌ Error reading file: \(filePath)\n   \(error)")
            }
        }
        
        // 6. Final summary
        reporter.reportSummary(summary, fileIssueMap: fileIssueMap)
    }

    /// Builds an `AISuggester` from runtime configuration and provider strategy.
    ///
    /// Provider selection rules:
    /// - `gemini`: requires `GEMINI_API_KEY`.
    /// - `local`: uses on-device provider only.
    /// - `hybrid`: cloud-first and falls back to local when cloud is unavailable.
    ///
    /// - Parameter configuration: Resolved AI runtime configuration.
    /// - Returns: Configured suggester or `nil` when AI is disabled/misconfigured.
    private static func buildAISuggester(configuration: AIConfiguration) -> AISuggester? {
        guard configuration.enabled else {
            return nil
        }

        let provider: AIProvider

        switch configuration.providerType {
        case .gemini:
            guard let apiKey = configuration.apiKey, !apiKey.isEmpty else {
                print("⚠️ AI is set to 'gemini' but GEMINI_API_KEY is missing.")
                return nil
            }
            provider = GeminiProvider(apiKey: apiKey, model: configuration.model)

        case .local:
            provider = LocalLLMProvider(modelPath: configuration.localModelPath, modelName: configuration.localModelName)

        case .hybrid:
            let cloud: AIProvider?
            if let apiKey = configuration.apiKey, !apiKey.isEmpty {
                cloud = GeminiProvider(apiKey: apiKey, model: configuration.model)
            } else {
                cloud = nil
                print("ℹ️ Hybrid mode running without GEMINI_API_KEY. Using local fallback path.")
            }
            
            let localPreferred = LocalLLMProvider(modelPath: configuration.localModelPath, modelName: configuration.localModelName, failIfStub: false)
            let localFallback = LocalLLMProvider(modelPath: nil, modelName: configuration.localModelName, failIfStub: false)
            provider = HybridAIProvider(
                localPreferred: localPreferred,
                localFallback: localFallback,
                cloud: cloud,
                preferLocal: false
            )
        }

        return AISuggester(
            provider: provider,
            maxSuggestions: configuration.maxSuggestions,
            snippetLineLimit: configuration.snippetLineLimit
        )
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
/// This allows users to keep AI runtime settings in one file instead of exporting shell
/// variables manually every run.
private enum EnvironmentFileLoader {
    private static let fileName = ".aianalyzer.env"

    static func apply(fromRootPath rootPath: String) {
        let fileURL = URL(fileURLWithPath: rootPath).appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
            print("⚠️ Could not read \(fileName); continuing with shell environment variables.")
            return
        }

        for (key, value) in parse(contents: contents) {
            setenv(key, value, 1)
        }
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
