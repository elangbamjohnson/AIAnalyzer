
import Foundation

// 1. A clean, simple struct (No issues)
struct User {
    let id: UUID
    let name: String
}

// 2. A "God Object" Struct
// This will trigger GodObject, LargeClass, and DataHeavyClass
struct MonsterStruct {
    // Too many properties (DataHeavy)
    var p1: Int = 0
    var p2: Int = 0
    var p3: Int = 0
    var p4: Int = 0
    var p5: Int = 0
    var p6: Int = 0
    var p7: Int = 0
    var p8: Int = 0
    var p9: Int = 0
    var p10: Int = 0
    var p11: Int = 0
    var p12: Int = 0
    var p13: Int = 0
    var p14: Int = 0
    var p15: Int = 0
    var p16: Int = 0
    var p17: Int = 0
    var p18: Int = 0
    var p19: Int = 0
    var p20: Int = 0
    var p21: Int = 0
    
    // Many accessors
    var status: String { "Active" }
    var formattedId: String { "ID-\(p1)" }
    var isReady: Bool { p2 > 10 }
    
    // Multiple initializers
    init() {}
    init(p1: Int) { self.p1 = p1 }
    init(all: Int) { self.p1 = all; self.p2 = all }
    
    // Too many methods (LargeClass)
    func save() { print("Saving...") }
    func load() { print("Loading...") }
    func validate() -> Bool { true }
    func process() { /* heavy logic */ }
    func sync() { /* network logic */ }
    func log() { print("Log") }
    func reset() { p1 = 0 }
    func update() { p1 += 1 }
    func delete() { print("Deleted") }
    func archive() { print("Archived") }
    func backup() { print("Backup") }
    func restore() { print("Restore") }
    func notify() { print("Notify") }
    func refresh() { print("Refresh") }
    func compute() { print("Compute") }
    func finalize() { print("Finalize") }
    func handle() { print("Handle") }
    func dispatch() { print("Dispatch") }
    func execute() { print("Execute") }
    func run() { print("Run") }
}

// 3. A logic-heavy class to test Member Map accuracy
class LogicService {
    func stepOne() {
        // Line 1
        // Line 2
        // Line 3
        print("1")
    }
    
    func stepTwo() {
        print("2")
    }
    
    func stepThree() {
        print("3")
    }
}
