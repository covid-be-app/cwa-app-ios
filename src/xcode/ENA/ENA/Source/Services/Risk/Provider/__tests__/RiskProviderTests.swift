//
// Corona-Warn-App
//
// SAP SE and all other contributors /
//
// Modified by Devside SRL
//
// copyright owners license this file to you under the Apache
// License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

import XCTest
import ZIPFoundation
import ExposureNotification

@testable import ENA

private final class Summary: ENExposureDetectionSummary {}

private final class ExposureSummaryProviderMock: ExposureSummaryProvider {
	var onDetectExposure: ((ExposureSummaryProvider.Completion) -> Void)?
	var onGetWindows: ((ExposureSummaryProvider.WindowsCompletion) -> Void)?

	func detectExposure(completion:@escaping (ENExposureDetectionSummary?) -> Void) {
		onDetectExposure?(completion)
	}
	
	func getWindows(summary: ENExposureDetectionSummary, completion: @escaping WindowsCompletion) {
		onGetWindows?(completion)
	}
}

func getApplicationConfiguration() -> SAP_Internal_V2_ApplicationConfigurationIOS {
	guard
		let url = Bundle.main.url(forResource: "default_app_config_200", withExtension: ""),
		let data = try? Data(contentsOf: url),
		let zip = Archive(data: data, accessMode: .read),
		let staticConfig = try? zip.extractAppConfiguration() else {
		fatalError("Could not fetch static app config")
	}
	return staticConfig
}

final class RiskProviderTests: XCTestCase {
	func testExposureDetectionIsExecutedIfLastDetectionIsToOldAndModeIsAutomatic() throws {
		let duration = DateComponents(day: 1)

		let calendar = Calendar.current

		let lastExposureDetectionDate = calendar.date(
			byAdding: .day,
			value: -3,
			to: Date(),
			wrappingComponents: false
		)

		let store = MockTestStore()
		store.summary = SummaryMetadata(
			summary: CodableExposureDetectionSummary(
				daysSinceLastExposure: 0,
				matchedKeyCount: 0,
				maximumRiskScore: 0,
				attenuationDurations: [],
				maximumRiskScoreFullRange: 0
			),
			// swiftlint:disable:next force_unwrapping
			date: lastExposureDetectionDate!
		)
		store.tracingStatusHistory = [.init(on: true, date: Date().addingTimeInterval(.init(days: -1)))]

		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: duration,
			exposureDetectionInterval: duration,
			detectionMode: .automatic
		)
		let exposureSummaryProvider = ExposureSummaryProviderMock()

		let expectThatSummaryIsRequested = expectation(description: "expectThatSummaryIsRequested")
		exposureSummaryProvider.onDetectExposure = { completion in
			store.summary = SummaryMetadata(detectionSummary: .init(), date: Date())
			expectThatSummaryIsRequested.fulfill()
			completion(.init())
		}

		let sut = RiskProvider(
			configuration: config,
			store: store,
			exposureSummaryProvider: exposureSummaryProvider,
			appConfigurationProvider: CachedAppConfiguration(client: ClientMock(submissionError: nil)),
			exposureManagerState: .init(authorized: true, enabled: true, status: .active)
		)

		let consumer = RiskConsumer()

		sut.observeRisk(consumer)
		sut.requestRisk(userInitiated: false)
		waitForExpectations(timeout: 1.0)
	}

	func testExposureDetectionIsNotExecutedIfTracingHasNotBeenEnabledLongEnough() throws {
		let duration = DateComponents(day: 1)

		let calendar = Calendar.current

		let lastExposureDetectionDate = calendar.date(
			byAdding: .day,
			value: -3,
			to: Date(),
			wrappingComponents: false
		)

		let store = MockTestStore()
		store.summary = SummaryMetadata(
			summary: CodableExposureDetectionSummary(
				daysSinceLastExposure: 0,
				matchedKeyCount: 0,
				maximumRiskScore: 0,
				attenuationDurations: [],
				maximumRiskScoreFullRange: 0
			),
			// swiftlint:disable:next force_unwrapping
			date: lastExposureDetectionDate!
		)
		// Tracing was only active for one hour, there is not enough data to calculate risk,
		// and we might get a rate limit error (ex. user reinstalls the app - losing tracing history - and risk is requested again)
		store.tracingStatusHistory = [.init(on: true, date: Date().addingTimeInterval(.init(hours: -1)))]

		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: duration,
			exposureDetectionInterval: duration,
			detectionMode: .automatic
		)
		let exposureSummaryProvider = ExposureSummaryProviderMock()

		let expectThatSummaryIsRequested = expectation(description: "expectThatSummaryIsRequested")
		exposureSummaryProvider.onDetectExposure = { completion in
			expectThatSummaryIsRequested.fulfill()
			completion(.init())
		}
		expectThatSummaryIsRequested.isInverted = true

		let sut = RiskProvider(
			configuration: config,
			store: store,
			exposureSummaryProvider: exposureSummaryProvider,
			appConfigurationProvider: CachedAppConfiguration(client: ClientMock(submissionError: nil)),
			exposureManagerState: .init(authorized: true, enabled: true, status: .active)
		)

		let consumer = RiskConsumer()

		sut.observeRisk(consumer)
		let expectThatRiskIsReturned = expectation(description: "expectThatRiskIsReturned")
		sut.requestRisk(userInitiated: false) { risk in
			expectThatRiskIsReturned.fulfill()
			XCTAssertEqual(risk?.level, .unknownInitial, "Tracing was active for < 24 hours but risk is not .unknownInitial")
		}
		waitForExpectations(timeout: 1.0)
	}

	func testThatDetectionIsRequested() throws {
		let duration = DateComponents(day: 1)

		let store = MockTestStore()
		store.summary = nil
		store.tracingStatusHistory = [.init(on: true, date: Date().addingTimeInterval(.init(days: -1)))]

		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: duration,
			exposureDetectionInterval: duration
		)

		let exposureSummaryProvider = ExposureSummaryProviderMock()

		let detectionRequested = expectation(description: "expectThatNoSummaryIsRequested")

		exposureSummaryProvider.onDetectExposure = { completion in
			completion(nil)
			detectionRequested.fulfill()
		}

		let client = ClientMock(submissionError: nil)

		client.onAppConfiguration = { complete in
			complete(SAP_Internal_V2_ApplicationConfigurationIOS.with {
				$0.riskCalculationParameters = SAP_Internal_V2_RiskCalculationParameters()
			})
		}

		let cachedAppConfig = CachedAppConfiguration(client: client)

		let sut = RiskProvider(
			configuration: config,
			store: store,
			exposureSummaryProvider: exposureSummaryProvider,
			appConfigurationProvider: cachedAppConfig,
			exposureManagerState: .init(authorized: true, enabled: true, status: .active)
		)

		let consumer = RiskConsumer()
		let didCalculateRiskCalled = expectation(
			description: "expect didCalculateRisk to be called"
		)

		consumer.didCalculateRisk = { _ in
			didCalculateRiskCalled.fulfill()
		}

		sut.observeRisk(consumer)
		sut.requestRisk(userInitiated: true)
		wait(for: [detectionRequested, didCalculateRiskCalled], timeout: 1.0, enforceOrder: true)
	}
	
	func testThatFailedFirstRiskReturnsInitial() throws {
		let duration = DateComponents(day: 1)

		let store = MockTestStore()
		store.summary = nil
		store.tracingStatusHistory = [.init(on: true, date: Date().addingTimeInterval(.init(days: -1)))]

		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: duration,
			exposureDetectionInterval: duration
		)

		let exposureSummaryProvider = ExposureSummaryProviderMock()

		exposureSummaryProvider.onDetectExposure = { completion in
			completion(nil)
		}

		let client = ClientMock(submissionError: nil, urlRequestFailure: .serverError(500))

		client.onAppConfiguration = { complete in
			complete(SAP_Internal_V2_ApplicationConfigurationIOS.with {
				$0.riskCalculationParameters = SAP_Internal_V2_RiskCalculationParameters()
			})
		}

		let cachedAppConfig = CachedAppConfiguration(client: client)

		let sut = RiskProvider(
			configuration: config,
			store: store,
			exposureSummaryProvider: exposureSummaryProvider,
			appConfigurationProvider: cachedAppConfig,
			exposureManagerState: .init(authorized: true, enabled: true, status: .active)
		)

		let consumer = RiskConsumer()
		let didCalculateRiskCalled = expectation(
			description: "expect didCalculateRisk to be called"
		)

		consumer.didCalculateRisk = { risk in
			XCTAssertEqual(risk.level, RiskLevel.unknownInitial)
			didCalculateRiskCalled.fulfill()
		}

		sut.observeRisk(consumer)
		sut.requestRisk(userInitiated: true)
		wait(for: [didCalculateRiskCalled], timeout: 10.0, enforceOrder: true)
	}
	
	func testThatLaterFailureReturnsPreviousRisk() throws {
		let duration = DateComponents(day: 1)

		let store = MockTestStore()
		store.summary = nil
		store.tracingStatusHistory = [.init(on: true, date: Date().addingTimeInterval(.init(days: -1)))]

		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: duration,
			exposureDetectionInterval: duration
		)

		let exposureSummaryProvider = ExposureSummaryProviderMock()

		exposureSummaryProvider.onDetectExposure = { completion in
			completion(nil)
		}
		
		exposureSummaryProvider.onGetWindows = { completion in
			completion([])
		}

		let client = ClientMock(submissionError: nil)

		client.onAppConfiguration = { complete in
			complete(SAP_Internal_V2_ApplicationConfigurationIOS.with {
				$0.riskCalculationParameters = SAP_Internal_V2_RiskCalculationParameters()
			})
		}

		let cachedAppConfig = CachedAppConfiguration(client: client)

		let sut = RiskProvider(
			configuration: config,
			store: store,
			exposureSummaryProvider: exposureSummaryProvider,
			appConfigurationProvider: cachedAppConfig,
			exposureManagerState: .init(authorized: true, enabled: true, status: .active)
		)

		let consumer = RiskConsumer()
		let didCalculateRiskCalled = expectation(
			description: "expect didCalculateRisk to be called"
		)

		consumer.didCalculateRisk = { risk in
			XCTAssertEqual(risk.level, RiskLevel.unknownInitial)
			didCalculateRiskCalled.fulfill()
		}

		sut.observeRisk(consumer)
		sut.requestRisk(userInitiated: true)
		wait(for: [didCalculateRiskCalled], timeout: 1000000.0, enforceOrder: true)

		let client2 = ClientMock()

		client2.onAppConfiguration = { complete in
			complete(getApplicationConfiguration())
		}

		let cachedAppConfig2 = CachedAppConfiguration(client: client2)

		let exposureSummaryProvider2 = ExposureSummaryProviderMock()

		exposureSummaryProvider2.onDetectExposure = { completion in
			// This is a low risk summary
			let summary = MutableENExposureDetectionSummary(
				daysSinceLastExposure: 0,
				matchedKeyCount: 0,
				maximumRiskScore: 0,
				attenuationDurations: [0, 0, 0],
				metadata: ["attenuationDurations": [30, 50, 70]]
			)
			completion(summary)
		}
		
		exposureSummaryProvider2.onGetWindows = { completion in
			let window = MutableENExposureWindow()
			
			completion([window])
		}

		let sut2 = RiskProvider(
			configuration: config,
			store: store,
			exposureSummaryProvider: exposureSummaryProvider2,
			appConfigurationProvider: cachedAppConfig2,
			exposureManagerState: .init(authorized: true, enabled: true, status: .active)
		)

		let consumer2 = RiskConsumer()
		let didCalculateRiskCalled2 = expectation(
			description: "expect didCalculateRisk 2 to be called"
		)
		consumer2.didCalculateRisk = { risk in
			XCTAssertEqual(risk.level, RiskLevel.low)
			didCalculateRiskCalled2.fulfill()
		}

		sut2.observeRisk(consumer2)
		sut2.requestRisk(userInitiated: true)
		wait(for: [didCalculateRiskCalled2], timeout: 100000.0, enforceOrder: true)

	}
}
