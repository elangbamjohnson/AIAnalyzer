//
//  AIAnalyzerTests.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Testing
import Foundation
import SwiftParser
@testable import AIAnalyzer

@Suite("Basic Rule Tests")
struct BasicRuleTests {
    
    @Test func testLargeClassRuleFallback() {
        let rule = LargeClassRule(threshold: 3)
        // Using .unknown type to test the fallback threshold
        let classInfo = ClassInfo(type: .unknown, name: "TestClass", methodCount: 4, propertyCount: 1, lineCount: 10)
        let issue = rule.evaluate(classInfo)
        
        #expect(issue != nil)
        #expect(issue?.severity == .warning)
    }
    
    @Test func testDataHeavyClassRule() {
        let rule = DataHeavyClassRule(threshold: 2)
        let classInfo = ClassInfo(type: .model, name: "TestData", methodCount: 1, propertyCount: 3, lineCount: 10)
        let issue = rule.evaluate(classInfo)
        
        #expect(issue != nil)
        #expect(issue?.ruleName == "DataHeavyClass")
    }
}

@Suite("Architectural Awareness Tests")
struct ArchitecturalTests {
    
    @Test func testContextAwareThresholds() {
        let rule = LargeClassRule()
        
        // A ViewController with 20 methods is considered OK (threshold 25)
        let vc = ClassInfo(type: .viewController, name: "MyVC", methodCount: 20, propertyCount: 5, lineCount: 200)
        #expect(rule.evaluate(vc) == nil)
        
        // A Model with 20 methods is considered CRITICAL (threshold 10, and 2x limit)
        let model = ClassInfo(type: .model, name: "MyModel", methodCount: 21, propertyCount: 2, lineCount: 50)
        let issue = rule.evaluate(model)
        #expect(issue != nil)
        #expect(issue?.severity == .critical)
    }
}

@Suite("GodObject Logic Tests")
struct GodObjectTests {
    
    @Test func testMultiSignalRequirement() {
        let rule = GodObjectRule()
        
        // Signal 1: High methods (45 for VC)
        // Signal 2: High properties (25 for VC)
        
        // Case A: Only 1 signal (too many methods, but few properties/lines)
        let oneSignal = ClassInfo(type: .viewController, name: "OneSignal", methodCount: 50, propertyCount: 5, lineCount: 100)
        #expect(rule.evaluate(oneSignal) == nil)
        
        // Case B: 2 signals (methods AND properties)
        let twoSignals = ClassInfo(type: .viewController, name: "TwoSignals", methodCount: 45, propertyCount: 25, lineCount: 100)
        let issue = rule.evaluate(twoSignals)
        #expect(issue != nil)
        #expect(issue?.severity == .critical)
    }
}

@Suite("Method Density Tests")
struct DensityTests {
    
    @Test func testHighMethodDensity() {
        let rule = HighMethodDensityRule()
        
        // 20 methods in only 40 lines (Avg 2 lines per method) -> High Density
        let fragmentedClass = ClassInfo(type: .service, name: "SmallMethods", methodCount: 20, propertyCount: 2, lineCount: 40)
        let issue = rule.evaluate(fragmentedClass)
        
        #expect(issue != nil)
        #expect(issue?.ruleName == "HighMethodDensity")
    }
    
    @Test func testDensityYieldToLargeClass() {
        let rule = HighMethodDensityRule()
        
        // If the class is very large (e.g. 500 lines), HighMethodDensity should yield to LargeClassRule
        let hugeClass = ClassInfo(type: .viewController, name: "Huge", methodCount: 30, propertyCount: 5, lineCount: 500)
        #expect(rule.evaluate(hugeClass) == nil)
    }
}

@Suite("Visitor Precision Tests")
struct VisitorTests {
    
    @Test func testTriviaExclusion() {
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
        
        #expect(visitor.classes.count == 1)
        let classInfo = visitor.classes[0]
        
        // The class itself is only 3 lines. The 3 leading comments should be ignored.
        #expect(classInfo.lineCount <= 4)
    }
}

@Suite("Visitor Struct Tests")
struct VisitorStructTests {
    @Test func testStructDetection() {
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
        
        #expect(visitor.classes.count == 1)
        let info = visitor.classes[0]
        #expect(info.name == "MyStruct")
        #expect(info.propertyCount == 2)
        #expect(info.methodCount == 1)
    }
}

private struct MockAIProvider: AIProvider {
    func suggest(for context: AIRequestContext) async throws -> AISuggestion {
        AISuggestion(
            metadata: .init(
                ruleName: context.issue.ruleName,
                typeName: context.classInfo?.name ?? "UnknownClass",
                severity: context.issue.severity
            ),
            content: .init(
                diagnosis: "mock diagnosis",
                modelSource: "MockProvider",
                suggestedRefactor: "mock refactor"
            )
        )
    }
}

private struct ThrowingAIProvider: AIProvider {
    func suggest(for context: AIRequestContext) async throws -> AISuggestion {
        throw AIProviderError.localUnavailable("Simulated provider failure")
    }
}

private struct StaticAIProvider: AIProvider {
    let diagnosis: String
    let suggestedRefactor: String
    let source: String = "StaticProvider"

    func suggest(for context: AIRequestContext) async throws -> AISuggestion {
        AISuggestion(
            metadata: .init(
                ruleName: context.issue.ruleName,
                typeName: context.classInfo?.name ?? "UnknownClass",
                severity: context.issue.severity
            ),
            content: .init(
                diagnosis: diagnosis,
                modelSource: source,
                suggestedRefactor: suggestedRefactor
            )
        )
    }
}

@Suite("AI Suggestion Tests")
struct AISuggesterTests {
    @Test func testGeneratesHighestSeveritySuggestionPerClassOnly() async {
        let suggester = AISuggester(provider: MockAIProvider(), maxSuggestions: 10, snippetLineLimit: 20)
        let classes = [ClassInfo(type: .model, name: "Demo", methodCount: 1, propertyCount: 1, lineCount: 10)]
        let issues = [
            Issue(ruleName: "InfoRule", message: "Class Demo info", severity: .info),
            Issue(ruleName: "WarnRule", message: "Class Demo warning", severity: .warning),
            Issue(ruleName: "CriticalRule", message: "Class Demo critical", severity: .critical)
        ]

        let suggestions = await suggester.generateSuggestions(
            issues: issues,
            classes: classes,
            sourceCode: "class Demo {}"
        )

        #expect(suggestions.count == 1)
        #expect(!suggestions.map(\.metadata.ruleName).contains("WarnRule"))
        #expect(suggestions.map(\.metadata.ruleName).contains("CriticalRule"))
    }

    @Test func testGeneratesPerClassSuggestionsAcrossDifferentClasses() async {
        let suggester = AISuggester(provider: MockAIProvider(), maxSuggestions: 10, snippetLineLimit: 20)
        let classes = [
            ClassInfo(type: .model, name: "Demo", methodCount: 1, propertyCount: 1, lineCount: 10),
            ClassInfo(type: .service, name: "Worker", methodCount: 1, propertyCount: 1, lineCount: 10)
        ]
        let issues = [
            Issue(ruleName: "DemoWarn", message: "Class Demo warning", severity: .warning),
            Issue(ruleName: "DemoCritical", message: "Class Demo critical", severity: .critical),
            Issue(ruleName: "WorkerWarn", message: "Class Worker warning", severity: .warning)
        ]

        let suggestions = await suggester.generateSuggestions(
            issues: issues,
            classes: classes,
            sourceCode: "class Demo {} class Worker {}"
        )

        #expect(suggestions.count == 2)
        #expect(suggestions.map(\.metadata.ruleName).contains("DemoCritical"))
        #expect(suggestions.map(\.metadata.ruleName).contains("WorkerWarn"))
    }
}

@Suite("Hybrid AI Provider Tests")
struct HybridAIProviderTests {
    private let demoContext = AIRequestContext(
        issue: Issue(ruleName: "LargeClass", message: "Demo issue", severity: .warning),
        classInfo: ClassInfo(type: .model, name: "Demo", methodCount: 20, propertyCount: 10, lineCount: 200),
        sourceSnippet: "class Demo {}"
    )

    @Test func testLocalFirstUsesCloudWhenLocalConfidenceIsLow() async throws {
        let lowConfidenceLocal = StaticAIProvider(diagnosis: "Local low confidence", suggestedRefactor: "too short")
        let cloud = StaticAIProvider(diagnosis: "Cloud diagnosis", suggestedRefactor: "Detailed cloud recommendation for reliable fallback behavior.")
        let localFallback = StaticAIProvider(diagnosis: "Fallback diagnosis", suggestedRefactor: "Fallback recommendation text")

        let provider = HybridAIProvider(
            localPreferred: lowConfidenceLocal,
            localFallback: localFallback,
            cloud: cloud,
            preferLocal: true
        )

        let suggestion = try await provider.suggest(for: demoContext)
        #expect(suggestion.content.diagnosis == "Cloud diagnosis")
    }

    @Test func testLocalFirstWithoutCloudFallsBackToLocalProvider() async throws {
        let failingLocal = ThrowingAIProvider()
        let localFallback = StaticAIProvider(
            diagnosis: "Local fallback diagnosis",
            suggestedRefactor: "A long and explicit local fallback recommendation with enough detail."
        )

        let provider = HybridAIProvider(
            localPreferred: failingLocal,
            localFallback: localFallback,
            cloud: nil,
            preferLocal: true
        )

        let suggestion = try await provider.suggest(for: demoContext)
        #expect(suggestion.content.diagnosis == "Local fallback diagnosis")
    }
}

@Suite("AIRequestContext Prompt Tests")
struct AIRequestContextPromptTests {
    private let context = AIRequestContext(
        issue: Issue(ruleName: "LargeClass", message: "Demo issue", severity: .warning),
        classInfo: ClassInfo(type: .model, name: "Demo", methodCount: 20, propertyCount: 10, lineCount: 200),
        sourceSnippet: "class Demo { func foo() {} }"
    )

    @Test func testStandardPromptContainsStructuralSections() {
        let prompt = context.buildPrompt(compact: false)

        #expect(prompt.contains("You are a senior Swift architect."))
        #expect(prompt.contains("Root cause"))
        #expect(prompt.contains("Refactor steps"))
        #expect(prompt.contains("Quick win"))
        #expect(prompt.contains("LargeClass"))
        #expect(prompt.contains("Demo"))
        #expect(prompt.contains("class Demo { func foo() {} }"))
    }

    @Test func testCompactPromptExcludesStructuralSections() {
        let prompt = context.buildPrompt(compact: true)

        #expect(prompt.contains("You are a Swift refactoring assistant."))
        #expect(!prompt.contains("You are a senior Swift architect."))
        #expect(!prompt.contains("Root cause"))
        #expect(!prompt.contains("Refactor steps"))
        #expect(!prompt.contains("Quick win"))
        #expect(prompt.contains("LargeClass"))
        #expect(prompt.contains("Demo"))
        #expect(prompt.contains("class Demo { func foo() {} }"))
    }

    @Test func testPromptDefaultsToStandardMode() {
        let prompt = context.buildPrompt()
        #expect(prompt.contains("You are a senior Swift architect."))
        #expect(prompt.contains("Root cause"))
    }
}

@Suite("Input Validation Tests")
struct InputValidationTests {

    @Test func testAllowsSwiftSingleFile() {
        let error = InputPathValidator.singleFileExtensionError(
            for: "/tmp/MyFile.swift",
            isDirectory: false
        )
        #expect(error == nil)
    }

    @Test func testRejectsNonSwiftSingleFile() {
        let error = InputPathValidator.singleFileExtensionError(
            for: "/tmp/Notes.txt",
            isDirectory: false
        )
        #expect(error == "❌ Single-file input must be a .swift file")
    }

    @Test func testSkipsExtensionValidationForDirectories() {
        let error = InputPathValidator.singleFileExtensionError(
            for: "/tmp/some-folder",
            isDirectory: true
        )
        #expect(error == nil)
    }
}

@Suite("Rule Engine Dedup Tests")
struct RuleEngineDedupTests {

    @Test func testGodObjectSuppressesRedundantStructuralIssues() {
        let engine = RuleEngine(
            rules: [
                LargeClassRule(),
                DataHeavyClassRule(),
                GodObjectRule()
            ]
        )

        let oversizedModel = ClassInfo(
            type: .model,
            name: "MonsterModel",
            methodCount: 30,
            propertyCount: 25,
            lineCount: 400
        )

        let issues = engine.analyze([oversizedModel])
        let ruleNames = Set(issues.map(\.ruleName))

        #expect(ruleNames.contains("GodObject"))
        #expect(!ruleNames.contains("LargeClass"))
        #expect(!ruleNames.contains("DataHeavyClass"))
        #expect(issues.count == 1)
    }
}
