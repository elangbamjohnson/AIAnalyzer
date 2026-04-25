//
//  Rule.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

public protocol Rule {
    var name: String { get }
    func evaluate(_ classInfo: ClassInfo) -> Issue?
}
