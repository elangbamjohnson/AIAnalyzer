//
//  ClassVisitorTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 13/05/26.
//

import XCTest
import SwiftParser
@testable import AIAnalyzer

final class VisitorTests: XCTestCase {

    func testTriviaExclusion() {
        let source = """
        // Leading License Header
        // More Comments
        // ----------------------
        class MyClass {
            func test() {}
        }
        """

        let sourceFile = Parser.parse(source: source)
        let visitor = ClassVisitor(viewMode: .all)
        visitor.walk(sourceFile)

        XCTAssertEqual(visitor.classes.count, 1)
        let classInfo = visitor.classes[0]
        XCTAssertTrue(classInfo.lineCount <= 4)
    }
}

final class VisitorStructTests: XCTestCase {

    func testStructDetection() {
        let source = """
        struct MyStruct {
            var a: Int = 1
            var b: Int = 2
            func process() {}
        }
        """

        let sourceFile = Parser.parse(source: source)
        let visitor = ClassVisitor(viewMode: .all)
        visitor.walk(sourceFile)

        XCTAssertEqual(visitor.classes.count, 1)
        let info = visitor.classes[0]
        XCTAssertEqual(info.name, "MyStruct")
        XCTAssertEqual(info.propertyCount, 2)
        XCTAssertEqual(info.methodCount, 1)
    }

    func testEnumActorExtensionDetection() {
        let source = """
        enum MyEnum {
            case one
            func foo() {}
        }
        actor MyActor {
            var state: Int = 0
            func update() {}
        }
        extension MyActor {
            func extra() {}
        }
        """

        let sourceFile = Parser.parse(source: source)
        let visitor = ClassVisitor(viewMode: .all)
        visitor.walk(sourceFile)

        XCTAssertEqual(visitor.classes.count, 3)
        XCTAssertTrue(visitor.classes.contains { $0.name == "MyEnum" && $0.methodCount == 1 })
        XCTAssertTrue(visitor.classes.contains { $0.name == "MyActor" && $0.methodCount == 1 })
        XCTAssertTrue(visitor.classes.contains { $0.name == "MyActor" && $0.methodCount == 1 })
    }
}
