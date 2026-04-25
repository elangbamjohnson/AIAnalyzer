import Testing
@testable import AIAnalyzer

@Suite("Rule Tests")
struct RuleTests {
    
    @Test func testLargeClassRule() {
        let rule = LargeClassRule(threshold: 3)
        let classInfo = ClassInfo(name: "TestClass", methodCount: 4, propertyCount: 1, lineCount: 10)
        let issue = rule.evaluate(classInfo)
        
        #expect(issue != nil)
        #expect(issue?.ruleName == "LargeClass")
        #expect(issue?.severity == .warning)
    }
    
    @Test func testDataHeavyClassRule() {
        let rule = DataHeavyClassRule(threshold: 2)
        let classInfo = ClassInfo(name: "TestClass", methodCount: 1, propertyCount: 3, lineCount: 10)
        let issue = rule.evaluate(classInfo)
        
        #expect(issue != nil)
        #expect(issue?.ruleName == "DataHeavyClass")
        #expect(issue?.severity == .info)
    }
    
    @Test func testRuleEngine() {
        let engine = RuleEngine(rules: [
            LargeClassRule(threshold: 3),
            DataHeavyClassRule(threshold: 2)
        ])
        
        let classes = [
            ClassInfo(name: "Large", methodCount: 5, propertyCount: 1, lineCount: 20),
            ClassInfo(name: "Heavy", methodCount: 1, propertyCount: 5, lineCount: 20),
            ClassInfo(name: "Clean", methodCount: 1, propertyCount: 1, lineCount: 10)
        ]
        
        let issues = engine.analyze(classes)
        #expect(issues.count == 2)
    }
}
