//
//  AIConfigurationTests.swift
//  AIAnalyzerTests
//
//  Created by Johnson Elangbam on 18/06/26.
//

import XCTest
@testable import AIAnalyzer

final class AIConfigurationTests: XCTestCase {

    func testDefaultsToLocalProviderWithCloudOptInDisabled() {
        withEnvironment([
            "AI_PROVIDER": nil,
            "AI_CLOUD_OPT_IN": nil
        ]) {
            let configuration = AIConfiguration.fromEnvironment()

            XCTAssertEqual(configuration.serviceConfig.providerType, .local)
            XCTAssertFalse(configuration.serviceConfig.cloudOptIn)
        }
    }

    func testCloudOptInParsesTrueValues() {
        withEnvironment([
            "AI_CLOUD_OPT_IN": "yes"
        ]) {
            let configuration = AIConfiguration.fromEnvironment()

            XCTAssertTrue(configuration.serviceConfig.cloudOptIn)
        }
    }

    func testUnknownProviderFallsBackToLocal() {
        withEnvironment([
            "AI_PROVIDER": "typo-provider"
        ]) {
            let configuration = AIConfiguration.fromEnvironment()

            XCTAssertEqual(configuration.serviceConfig.providerType, .local)
        }
    }

    private func withEnvironment(_ updates: [String: String?], operation: () -> Void) {
        var captured: [String: String?] = [:]

        for key in updates.keys {
            captured[key] = currentEnvironmentValue(for: key)
        }

        for (key, value) in updates {
            if let value {
                setenv(key, value, 1)
            } else {
                unsetenv(key)
            }
        }

        operation()

        for (key, value) in captured {
            if let value {
                setenv(key, value, 1)
            } else {
                unsetenv(key)
            }
        }
    }

    private func currentEnvironmentValue(for key: String) -> String? {
        guard let pointer = getenv(key) else {
            return nil
        }
        return String(cString: pointer)
    }
}
