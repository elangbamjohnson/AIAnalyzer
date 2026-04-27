//
//  Severity.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

/// Defines the level of importance or impact for a detected issue, using emoji identifiers.
public enum Severity: String, Codable {
    /// Informational message (ℹ️), usually suggesting minor improvements.
    case info = "ℹ️"
    
    /// Warning message (⚠️), indicating potential code smells that should be reviewed.
    case warning = "⚠️"
    
    /// Critical error (🔴), indicating significant architectural violations.
    case critical = "🔴"
}
