import Foundation

public protocol Reporter {
    func report(issues: [Issue], filePath: String)
}
