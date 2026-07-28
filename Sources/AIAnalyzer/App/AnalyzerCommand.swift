//
//  AnalyzerCommand.swift
//  AIAnalyzer
//

import ArgumentParser
import Foundation

/// Command-line entry point using swift-argument-parser.
@main
struct AnalyzerCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "aianalyzer",
        abstract: "AI-assisted Swift static code analyzer.",
        discussion: """
        Examples:
          aianalyzer Sources
          aianalyzer MyApp --format sarif > aianalyzer.sarif
          aianalyzer MyApp --format xcode --fail-on-critical
        """
    )

    @Argument(help: "Swift file or project folder to analyze.")
    var inputPath: String = "sample.swift"

    @Option(name: .long, help: "Choose output format (console|json|xcode|sarif).")
    var format: OutputFormat = .console

    @Flag(name: .long, help: "Shortcut for --format json.")
    var json: Bool = false

    @Flag(name: .long, help: "Shortcut for --format xcode.")
    var xcode: Bool = false

    @Flag(name: .long, help: "Exit 1 when critical issues are found.")
    var failOnCritical: Bool = false

    @Flag(name: .long, help: "Exit 1 when warning or critical issues are found.")
    var failOnWarning: Bool = false

    @Flag(name: .long, help: "Exit 1 when any issue is found.")
    var strict: Bool = false

    var resolvedFormat: OutputFormat {
        if json { return .json }
        if xcode { return .xcode }
        return format
    }

    mutating func run() async throws {
        let options = AnalysisOptions(
            inputPath: inputPath,
            outputFormat: resolvedFormat,
            failOnWarning: failOnWarning,
            failOnCritical: failOnCritical,
            strict: strict
        )
        let orchestrator = AnalysisOrchestrator(options: options)
        let exitCode = await orchestrator.run()
        if exitCode != 0 {
            throw ExitCode(exitCode)
        }
    }
}
