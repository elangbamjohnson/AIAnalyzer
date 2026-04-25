//
//  Issue.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

public struct Issue: Codable {
    public let ruleName: String
    public let message: String
    public let severity: Severity
    public let line: Int?
}
