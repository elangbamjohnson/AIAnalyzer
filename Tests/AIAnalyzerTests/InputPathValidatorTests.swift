//
//  InputPathValidatorTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//

import XCTest
@testable import AIAnalyzer

final class InputValidationTests: XCTestCase {

    func testAllowsSwiftSingleFile() {
        let error = InputPathValidator.singleFileExtensionError(
            for: "/tmp/MyFile.swift",
            isDirectory: false
        )
        XCTAssertNil(error)
    }

    func testRejectsNonSwiftSingleFile() {
        let error = InputPathValidator.singleFileExtensionError(
            for: "/tmp/Notes.txt",
            isDirectory: false
        )
        XCTAssertEqual(error, "❌ Single-file input must be a .swift file")
    }

    func testSkipsExtensionValidationForDirectories() {
        let error = InputPathValidator.singleFileExtensionError(
            for: "/tmp/some-folder",
            isDirectory: true
        )
        XCTAssertNil(error)
    }
}
