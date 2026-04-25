import Foundation

public class RuleEngine {
    private let rules: [Rule]
    
    public init(rules: [Rule]) {
        self.rules = rules
    }
    
    public func analyze(_ classes: [ClassInfo]) -> [Issue] {
        var issues: [Issue] = []
        for classInfo in classes {
            for rule in rules {
                if let issue = rule.evaluate(classInfo) {
                    issues.append(issue)
                }
            }
        }
        return issues
    }
}
