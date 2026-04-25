//
//  Reporter.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

public protocol Reporter {
    func report(issues: [Issue], filePath: String)
}
