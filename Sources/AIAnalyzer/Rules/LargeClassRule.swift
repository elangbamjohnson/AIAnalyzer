import Foundation

public struct LargeClassRule: Rule {
    public let name = "LargeClass"
    private let threshold: Int
    
    public init(threshold: Int = 10) {
        self.threshold = threshold
    }
    
    public func evaluate(_ classInfo: ClassInfo) -> Issue? {
        if classInfo.methodCount > threshold {
            return Issue(
                ruleName: name,
                message: "Class \(classInfo.name) has too many methods (\(classInfo.methodCount)).",
                severity: .warning,
                line: nil
            )
        }
        return nil
    }
}
