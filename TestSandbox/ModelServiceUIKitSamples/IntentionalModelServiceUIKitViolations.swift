//
//  IntentionalModelServiceUIKitViolations.swift
//  AIAnalyzer TestSandbox
//
//  Created by Johnson Elangbam on 13/05/26.
//
//  This file exists to exercise `ModelServiceUIKitRule` (rule name: `ModelServiceUIKitViolation`).
//
//  Why run this path directly:
//  The repo `.aianalyzer.json` ignores the `TestSandbox` directory when scanning a folder, so
//  recursive scans from the project root skip this tree. Analyze this file explicitly, e.g.:
//
//    AI_ENABLED=false swift run AIAnalyzer TestSandbox/ModelServiceUIKitSamples/IntentionalModelServiceUIKitViolations.swift
//
//  Expected: two critical issues — one for the model-shaped type, one for the service-shaped type,
//  both because the file imports UIKit while `ClassVisitor` classifies them as `.model` / `.service`.
//

import Foundation
import UIKit

/// Name contains "model" → `ClassInfo.type == .model`; file imports UIKit → violation.
struct UserAccountModel {
    let userId: String
    let avatarTint: UIColor
}

/// Name contains "manager" → `ClassInfo.type == .service`; file imports UIKit → violation.
final class ReceiptExportManager {
    func icon() -> UIImage? {
        nil
    }
}
