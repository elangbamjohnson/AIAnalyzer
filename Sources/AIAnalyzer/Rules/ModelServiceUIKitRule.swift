//
//  ModelServiceUIKitRule.swift
//  AIAnalyzer
//
//  Created by Johnson Elangbam on 13/05/26.
//

import Foundation

/// Layering rule: domain and service types should not depend on UIKit.
///
/// Models (`*model*` name heuristic) and services (`*service*`, `*manager*`) are expected to stay
/// UI-framework-free so they remain testable and reusable. UIKit belongs in the view layer.
///
/// **Detected pattern**: a type classified as `.model` or `.service` whose file imports `UIKit`
/// (including `UIKit.*` submodule imports).
public struct ModelServiceUIKitRule: Rule {
    public let name = "ModelServiceUIKitViolation"

    public init() {}

    public func evaluate(_ classInfo: ClassInfo) -> Issue? {
        guard classInfo.type == .model || classInfo.type == .service else {
            return nil
        }

        let importsUIKit = classInfo.imports.contains { $0 == "UIKit" || $0.hasPrefix("UIKit.") }
        guard importsUIKit else { return nil }

        let layerLabel = classInfo.type == .model ? "Model" : "Service"
        return Issue(
            ruleName: name,
            message: "⚠️ Layering violation: '\(classInfo.name)' is classified as a \(layerLabel) but its file imports UIKit. "
                + "Keep UIKit out of data and service layers; move UI types and colors to the view layer or a dedicated UI module.",
            severity: .critical,
            line: nil
        )
    }
}
