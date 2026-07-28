//
//  AnalyzerCommandTests.swift
//  AIAnalyzerTests
//

import XCTest
import ArgumentParser
@testable import AIAnalyzer

final class AnalyzerCommandTests: XCTestCase {
    func testDefaultArguments() throws {
        let command = try AnalyzerCommand.parse([])
        XCTAssertEqual(command.inputPath, "sample.swift")
        XCTAssertEqual(command.format, .console)
        XCTAssertFalse(command.json)
        XCTAssertFalse(command.xcode)
        XCTAssertFalse(command.strict)
        XCTAssertFalse(command.failOnWarning)
        XCTAssertFalse(command.failOnCritical)
        XCTAssertEqual(command.resolvedFormat, .console)
    }

    func testPositionalInputPath() throws {
        let command = try AnalyzerCommand.parse(["Sources/AIAnalyzer"])
        XCTAssertEqual(command.inputPath, "Sources/AIAnalyzer")
    }

    func testJsonFlagShortcut() throws {
        let command = try AnalyzerCommand.parse(["--json", "Sources"])
        XCTAssertTrue(command.json)
        XCTAssertEqual(command.resolvedFormat, .json)
    }

    func testXcodeFlagShortcut() throws {
        let command = try AnalyzerCommand.parse(["--xcode", "Sources"])
        XCTAssertTrue(command.xcode)
        XCTAssertEqual(command.resolvedFormat, .xcode)
    }

    func testExplicitFormatOption() throws {
        let command = try AnalyzerCommand.parse(["--format", "sarif", "Sources"])
        XCTAssertEqual(command.format, .sarif)
        XCTAssertEqual(command.resolvedFormat, .sarif)
    }

    func testQualityGateFlags() throws {
        let command = try AnalyzerCommand.parse(["--strict", "--fail-on-warning", "--fail-on-critical", "Sources"])
        XCTAssertTrue(command.strict)
        XCTAssertTrue(command.failOnWarning)
        XCTAssertTrue(command.failOnCritical)
    }
}
