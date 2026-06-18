//
//  XcodeReporterTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 17/06/26.
//

import XCTest
@testable import AIAnalyzer

final class XcodeReporterTests: XCTestCase {

    func testRelativeFilePathResolvesUnderRootPath() {
        let output = captureStandardOutput {
            let reporter = XcodeReporter(rootPath: "/tmp/App")
            reporter.report(
                file: "Sources/Feature/ViewModel.swift",
                classes: [],
                issues: [
                    Issue(
                        ruleName: "LargeClass",
                        message: "Type Demo is too large",
                        severity: .warning,
                        line: 42
                    )
                ]
            )
        }

        XCTAssertTrue(output.contains("/tmp/App/Sources/Feature/ViewModel.swift:42: warning: [AIAnalyzer] Type Demo is too large"))
    }

    func testAbsoluteFilePathIsNotNestedUnderRootPath() {
        let output = captureStandardOutput {
            let reporter = XcodeReporter(rootPath: "/tmp/App")
            reporter.report(
                file: "/tmp/Other/ViewModel.swift",
                classes: [],
                issues: [
                    Issue(
                        ruleName: "GodObject",
                        message: "Type Demo is a God Object",
                        severity: .critical,
                        line: 7
                    )
                ]
            )
        }

        XCTAssertTrue(output.contains("/tmp/Other/ViewModel.swift:7: error: [AIAnalyzer] Type Demo is a God Object"))
        XCTAssertFalse(output.contains("/tmp/App/tmp/Other/ViewModel.swift"))
    }

    private func captureStandardOutput(_ operation: () -> Void) -> String {
        let pipe = Pipe()
        let originalStdout = dup(STDOUT_FILENO)

        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        operation()
        fflush(stdout)
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)

        pipe.fileHandleForWriting.closeFile()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
