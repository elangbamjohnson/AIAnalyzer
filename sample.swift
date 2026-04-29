
class HomeViewModel {
    
    func fetchData() {}
    func processData() {}
    func updateUI() {}
    func saveData() {}
    private let name = "Johnson"
    var age = 23, a = 3, address = "Imphal", c = 4, d = 5
}

class View {
    func display() {}
    func print() {}
    public let address = "Sagolaband"
    var age = 27
}

class MassiveViewModel {
    var a = 1, b = 2, c = 3
    
    func f1() {}
    func f2() {}
    func f3() {}
    func f4() {}
    func f5() {}
    func f6() {}
    func f7() {}
    func f8() {}
    func f9() {}
    func f10() {}
    func f11() {}
    func f12() {}
}

// Triggers HighMethodDensity (warning): many small methods in a medium-sized class.
class DenseService {
    func m1() {}
    func m2() {}
    func m3() {}
    func m4() {}
    func m5() {}
    func m6() {}
    func m7() {}
    func m8() {}
    func m9() {}
    func m10() {}
    func m11() {}
    func m12() {}
    func m13() {}
    func m14() {}
}

// Triggers GodObject (critical): exceeds model method and property limits.
class MonsterModel {
    var p1 = 1, p2 = 2, p3 = 3, p4 = 4, p5 = 5
    var p6 = 6, p7 = 7, p8 = 8, p9 = 9, p10 = 10
    var p11 = 11, p12 = 12, p13 = 13, p14 = 14, p15 = 15
    var p16 = 16, p17 = 17, p18 = 18, p19 = 19, p20 = 20
    var p21 = 21, p22 = 22, p23 = 23

    func step1() {}
    func step2() {}
    func step3() {}
    func step4() {}
    func step5() {}
    func step6() {}
    func step7() {}
    func step8() {}
    func step9() {}
    func step10() {}
    func step11() {}
    func step12() {}
    func step13() {}
    func step14() {}
    func step15() {}
    func step16() {}
    func step17() {}
}
