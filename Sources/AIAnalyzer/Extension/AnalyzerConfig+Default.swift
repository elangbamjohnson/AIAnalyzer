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
                largeClass: LargeClassRuleConfig(
                    enabled: true,
                    threshold: RuleConstants.largeClassThreshold,
                    vcMethods: RuleConstants.LargeClass.vcMethods,
                    vcLines: RuleConstants.LargeClass.vcLines,
                    vmMethods: RuleConstants.LargeClass.vmMethods,
                    vmLines: RuleConstants.LargeClass.vmLines,
                    serviceMethods: RuleConstants.LargeClass.serviceMethods,
                    serviceLines: RuleConstants.LargeClass.serviceLines,
                    modelMethods: RuleConstants.LargeClass.modelMethods,
                    modelLines: RuleConstants.LargeClass.modelLines
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
                ),
                viewModelUIKit: RuleToggle(
                    enabled: true,
                    threshold: nil
                ),
                modelServiceUIKit: RuleToggle(
                    enabled: true,
                    threshold: nil
                )
            )
        )
    }
}
