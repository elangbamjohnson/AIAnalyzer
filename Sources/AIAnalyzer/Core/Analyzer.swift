import Foundation
import SwiftSyntax
import SwiftParser

public class Analyzer {
    private let ruleEngine: RuleEngine
    
    public init(rules: [Rule]) {
        self.ruleEngine = RuleEngine(rules: rules)
    }
    
    public func analyze(fileURL: URL) throws -> [Issue] {
        let source = try String(contentsOf: fileURL, encoding: .utf8)
        let sourceFile = Parser.parse(source: source)
        
        let visitor = ClassVisitor(viewMode: .all)
        visitor.walk(sourceFile)
        
        return ruleEngine.analyze(visitor.classes)
    }
}
