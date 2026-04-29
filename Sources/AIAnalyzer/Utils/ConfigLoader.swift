//
//  ConfigLoader.swift
//  AIAnalyzer
//
//  Created by Johnson on 28/04/26.
//
import Foundation

class ConfigLoader {
    
    static func load(from rootPath: String) -> AnalyzerConfig {
        
        let fm = FileManager.default
        
        let jsonPath = "\(rootPath)/.aianalyzer.json"
        
        if fm.fileExists(atPath: jsonPath) {
            return loadJSON(from: jsonPath)
        }
        
        return .default
    }
    
    private static func loadJSON(from path: String) -> AnalyzerConfig {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let userConfig = try JSONDecoder().decode(AnalyzerConfig.self, from: data)
            return merge(userConfig)
        } catch {
            print("❌ Failed to load config: \(error)")
            return .default
        }
    }
    
    private static func merge(_ user: AnalyzerConfig) -> AnalyzerConfig {
        
        var config = AnalyzerConfig.default
        
        if let ignore = user.ignoreDirectories {
            config.ignoreDirectories = Array(Set(config.ignoreDirectories ?? []).union(Set(ignore)))
        }
        
        if let userRules = user.rules {
            var mergedRules = config.rules ?? AnalyzerConfig.RuleConfig()

            // largeClass
            if let userLarge = userRules.largeClass {
                var current = mergedRules.largeClass ?? AnalyzerConfig.RuleToggle()
                if let enabled = userLarge.enabled { current.enabled = enabled }
                if let threshold = userLarge.threshold { current.threshold = threshold }
                mergedRules.largeClass = current
            }

            // highMethodDensity
            if let userDensity = userRules.highMethodDensity {
                var current = mergedRules.highMethodDensity ?? AnalyzerConfig.RuleToggle()
                if let enabled = userDensity.enabled { current.enabled = enabled }
                if let threshold = userDensity.threshold { current.threshold = threshold }
                mergedRules.highMethodDensity = current
            }

            // godObject
            if let userGod = userRules.godObject {
                var current = mergedRules.godObject ?? AnalyzerConfig.RuleToggle()
                if let enabled = userGod.enabled { current.enabled = enabled }
                mergedRules.godObject = current
            }

            // dataHeavyClass
            if let userDataHeavy = userRules.dataHeavyClass {
                var current = mergedRules.dataHeavyClass ?? AnalyzerConfig.RuleToggle()
                if let enabled = userDataHeavy.enabled { current.enabled = enabled }
                if let threshold = userDataHeavy.threshold { current.threshold = threshold }
                mergedRules.dataHeavyClass = current
            }

            config.rules = mergedRules
        }
        
        return config
    }
    
    
}
