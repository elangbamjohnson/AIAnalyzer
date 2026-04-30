//
//  AnalyzerConfig+Default.swift
//  AIAnalyzer
//
//  Created by Johnson on 28/04/26.
//

extension AnalyzerConfig {
    
    public static var `default`: AnalyzerConfig {
        return AnalyzerConfig(
            ignoreDirectories: [
                ".build", ".git", ".swiftpm",
                "DerivedData", "Pods", "Build", "Carthage"
            ],
            rules: RuleConfig(
                largeClass: RuleToggle(
                    enabled: true,
                    threshold: RuleConstants.largeClassThreshold
                ),
                highMethodDensity: RuleToggle(
                    enabled: true,
                    threshold: RuleConstants.tooManyMethodThreshold
                ),
                godObject: RuleToggle(
                    enabled: true,
                    threshold: nil
                ),
                dataHeavyClass: RuleToggle(
                    enabled: true,
                    threshold: RuleConstants.dataHeavyClassThreshold
                )
            )
        )
    }
}
