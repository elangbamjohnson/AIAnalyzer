import Foundation

public protocol Rule {
    var name: String { get }
    func evaluate(_ classInfo: ClassInfo) -> Issue?
}
