//
//  ViewModelUIKitRule.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 25/04/26.
//
import Foundation

/// An architectural rule that enforces the MVVM contract:
/// a ViewModel must not import UIKit.
///
/// In a well-structured MVVM application the ViewModel is responsible for
/// business/presentation logic and should be fully decoupled from UIKit.
/// Importing UIKit in a ViewModel creates a tight coupling to the UI framework,
/// makes unit testing harder, and is a clear MVVM violation.
///
/// **Detected pattern**: any type whose name ends with `ViewModel` (case-insensitive)
/// that resides in a file that imports `UIKit`.
public struct ViewModelUIKitRule: Rule {
    /// The display name for this rule.
    public let name = "ViewModelUIKitViolation"

    public init() {}

    /// Evaluates whether a ViewModel type imports UIKit.
    /// - Parameter classInfo: The class metadata to evaluate.
    /// - Returns: A `.critical` `Issue` if the violation is detected, otherwise `nil`.
    public func evaluate(_ classInfo: ClassInfo) -> Issue? {
        // Only applies to types classified as a ViewModel.
        guard classInfo.type == .viewModel else { return nil }

        // Check whether UIKit appears in the file-level import list.
        let importsUIKit = classInfo.imports.contains { $0 == "UIKit" || $0.hasPrefix("UIKit.") }
        guard importsUIKit else { return nil }

        return Issue(
            ruleName: name,
            message: "⚠️ MVVM Violation: '\(classInfo.name)' is a ViewModel but its file imports UIKit. "
                   + "ViewModels must be framework-agnostic. Move UIKit code to the View layer.",
            severity: .critical,
            line: nil
        )
    }
}
