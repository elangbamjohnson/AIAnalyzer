//
//  AnalysisOrchestrator.swift
//  AIAnalyzer
//

import ArgumentParser
import Foundation
import SwiftParser
import SwiftSyntax

/// Supported output formats for code analysis reports.
public enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
    case console
    case json
    case xcode
    case sarif

    public var isMachineReadable: Bool {
        self == .json || self == .sarif
    }
}

/// Options configuring the analysis execution.
public struct AnalysisOptions {
    public let inputPath: String
    public let outputFormat: OutputFormat
    public let failOnWarning: Bool
    public let failOnCritical: Bool
    public let strict: Bool

    public var isJsonMode: Bool { outputFormat == .json }
    public var isXcodeMode: Bool { outputFormat == .xcode }
    public var isSarifMode: Bool { outputFormat == .sarif }
    public var isMachineReadable: Bool { outputFormat.isMachineReadable }

    public init(
        inputPath: String,
        outputFormat: OutputFormat,
        failOnWarning: Bool,
        failOnCritical: Bool,
        strict: Bool
    ) {
        self.inputPath = inputPath
        self.outputFormat = outputFormat
        self.failOnWarning = failOnWarning
        self.failOnCritical = failOnCritical
        self.strict = strict
    }
}

/// Core engine orchestrator that coordinates file scanning, syntax parsing, rule evaluation, reporting, and AI suggestions.
public struct AnalysisOrchestrator {
    private let options: AnalysisOptions

    public init(options: AnalysisOptions) {
        self.options = options
    }

    /// Executes the full analysis pipeline and returns the process exit code.
    public func run() async -> Int32 {
        let fullPath = URL(fileURLWithPath: options.inputPath).standardized.path
        
        var isDirectory: ObjCBool = false
        
        guard FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory) else {
            emitError("Path does not exist", isJsonMode: options.isJsonMode)
            return 1
        }

        if let validationError = InputPathValidator.singleFileExtensionError(
            for: fullPath,
            isDirectory: isDirectory.boolValue
        ) {
            emitError(validationError, isJsonMode: options.isJsonMode)
            return 1
        }
        
        // Determine root for config
        let rootPath = isDirectory.boolValue
            ? fullPath
            : URL(fileURLWithPath: fullPath).deletingLastPathComponent().path

        EnvironmentResolver.apply(fromRootPath: rootPath, isJsonMode: options.isMachineReadable)
        
        let config = ConfigLoader.load(from: rootPath)
        
        // Scan files
        let filePaths: [String]
        
        if isDirectory.boolValue {
            if options.outputFormat == .console { print("📂 Scanning folder: \(fullPath)") }
            filePaths = FileScanner.getSwiftFiles(in: fullPath, ignoring: config.ignoreDirectories)
        } else {
            filePaths = [fullPath]
        }
        
        guard !filePaths.isEmpty else {
            if options.outputFormat == .console { print("⚠️ No Swift files found.") }
            return 0
        }
        
        if options.outputFormat == .console { print("📊 Found \(filePaths.count) Swift files\n") }
        
        // Build rules from config
        var rules: [Rule] = []
        
        if config.rules?.largeClass?.enabled == true {
            let lc = config.rules?.largeClass
            rules.append(LargeClassRule(
                threshold: lc?.threshold ?? RuleConstants.largeClassThreshold,
                vcMethods: lc?.vcMethods ?? RuleConstants.LargeClass.vcMethods,
                vcLines: lc?.vcLines ?? RuleConstants.LargeClass.vcLines,
                vmMethods: lc?.vmMethods ?? RuleConstants.LargeClass.vmMethods,
                vmLines: lc?.vmLines ?? RuleConstants.LargeClass.vmLines,
                serviceMethods: lc?.serviceMethods ?? RuleConstants.LargeClass.serviceMethods,
                serviceLines: lc?.serviceLines ?? RuleConstants.LargeClass.serviceLines,
                modelMethods: lc?.modelMethods ?? RuleConstants.LargeClass.modelMethods,
                modelLines: lc?.modelLines ?? RuleConstants.LargeClass.modelLines
            ))
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
        
        // Process files
        for filePath in filePaths {
            do {
                let source = try String(contentsOf: URL(fileURLWithPath: filePath), encoding: .utf8)
                let sourceFile = Parser.parse(source: source)
                
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
                    reporter.report(file: displayPath, classes: visitor.classes, issues: issues)

                    if let suggester = AISuggesterFactory.build(configuration: aiConfiguration) {
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
        
        // Final summary
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

        return finalExitCode(
            summary: summary,
            hasProcessingErrors: hasProcessingErrors,
            options: options
        )
    }

    private func emitError(_ message: String, isJsonMode: Bool) {
        if isJsonMode {
            fputs("ERROR: \(message)\n", stderr)
        } else {
            print("❌ \(message)")
        }
    }

    private func finalExitCode(
        summary: AnalysisSummary,
        hasProcessingErrors: Bool,
        options: AnalysisOptions
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

    private func inferTypeName(for issue: Issue, classes: [ClassInfo]) -> String {
        for classInfo in classes where issue.message.contains(classInfo.name) {
            return classInfo.name
        }
        return classes.first?.name ?? "UnknownType"
    }

    private func relativePath(for filePath: String, rootPath: String) -> String {
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

    private func reportAISuggestions(_ suggestions: [AISuggestion], file: String) {
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

    private func reportAISuggestionsForXcode(
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

    private func printWithTypewriterEffect(_ text: String, delayMs: Int) {
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
