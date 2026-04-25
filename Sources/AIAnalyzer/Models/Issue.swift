import Foundation

public struct Issue: Codable {
    public let ruleName: String
    public let message: String
    public let severity: Severity
    public let line: Int?
}
