//
// Corona-Warn-App
//
// SAP SE and all other contributors
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

@testable import ENA
import ExposureNotification
import XCTest

final class RiskCalculationTests: XCTestCase {

	private let store = MockTestStore()
	private let riskCalculation = RiskCalculation()

	// MARK: - Tests for calculating raw risk score

	func testCalculateRawRiskScore_Zero() throws {
		let summaryZeroMaxRisk = makeExposureSummaryContainer(maxRiskScoreFullRange: 0, ad_low: 10, ad_mid: 10, ad_high: 10)
		XCTAssertEqual(riskCalculation.calculateRawRisk(summary: summaryZeroMaxRisk, configuration: appConfig), 0.0, accuracy: 0.01)
	}

	func testCalculateRawRiskScore_Low() throws {
		XCTAssertEqual(riskCalculation.calculateRawRisk(summary: summaryLow, configuration: appConfig), 1.07, accuracy: 0.01)
	}

	func testCalculateRawRiskScore_Med() throws {
		XCTAssertEqual(riskCalculation.calculateRawRisk(summary: summaryMed, configuration: appConfig), 2.56, accuracy: 0.01)
	}

	func testCalculateRawRiskScore_High() throws {
		XCTAssertEqual(riskCalculation.calculateRawRisk(summary: summaryHigh, configuration: appConfig), 10.2, accuracy: 0.01)
	}

	// MARK: - Tests for calculating risk levels

	func testCalculateRisk_Inactive() {
		// Test the condition when the risk is returned as inactive
		// This occurs when the preconditions are not met, ex. when tracing is off.
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)
		let risk = riskCalculation.risk(
			summary: summaryHigh,
			configuration: appConfig,
			dateLastExposureDetection: Date(),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.invalid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)

		XCTAssertEqual(risk?.level, .inactive)
	}

	func testCalculateRisk_UnknownInitial() {
		// Test the condition when the risk is returned as unknownInitial

		// That will happen when:
		// 1. The number of hours tracing has been active for is less than one day
		// 2. There is no ENExposureDetectionSummary to use

		// Test case for tracing not being active long enough
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)
		var risk = riskCalculation
			.risk(
				summary: summaryLow,
				configuration: appConfig,
				dateLastExposureDetection: Date(),
				activeTracing: .init(interval: 0),
				preconditions: preconditions(.valid),
				previousRiskLevel: nil,
				providerConfiguration: config
		)

		XCTAssertEqual(risk?.level, .unknownInitial)

		// Test case when summary is nil
		risk = riskCalculation.risk(
			summary: nil,
			configuration: appConfig,
			dateLastExposureDetection: Date(),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)

		XCTAssertEqual(risk?.level, .unknownInitial)
	}

	func testCalculateRisk_UnknownOutdated() {
		// Test the condition when the risk is returned as unknownOutdated.

		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// That will happen when the date of last exposure detection is older than one day
		let risk = riskCalculation.risk(
			summary: summaryLow,
			configuration: appConfig,
			dateLastExposureDetection: Date().addingTimeInterval(.init(days: -2)),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)

		// :BE: We currently disabled this
		//XCTAssertEqual(risk?.level, .unknownOutdated)
		XCTAssertEqual(risk?.level, .low)
	}

	func testCalculateRisk_UnknownOutdated2() {
		// Test the condition when the risk is returned as unknownOutdated.

		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 2),
			exposureDetectionInterval: .init(day: 2),
			detectionMode: .automatic
		)

		// That will happen when the date of last exposure detection is older than one day
		let risk = riskCalculation.risk(
			summary: nil,
			configuration: appConfig,
			dateLastExposureDetection: Date().addingTimeInterval(.init(days: -1)),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)

		XCTAssertEqual(risk?.level, .unknownInitial)

		// :BE: We currently disabled this
		XCTAssertEqual(
			riskCalculation.risk(
				summary: summaryLow,
				configuration: appConfig,
				dateLastExposureDetection: Date().addingTimeInterval(.init(days: -3)),
				activeTracing: .init(interval: 48 * 3600),
				preconditions: preconditions(.valid),
				previousRiskLevel: nil,
				providerConfiguration: config
				)?.level,
		//	.unknownOutdated
			.low
		)

		XCTAssertEqual(
			riskCalculation.risk(
				summary: summaryLow,
				configuration: appConfig,
				dateLastExposureDetection: Date().addingTimeInterval(.init(days: -1)),
				activeTracing: .init(interval: 48 * 3600),
				preconditions: preconditions(.valid),
				previousRiskLevel: nil,
				providerConfiguration: config
				)?.level,
			.low
		)
	}


	func testCalculateRisk_LowRisk() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// Test the case where preconditions pass and there is low risk
		let risk = riskCalculation.risk(
			summary: summaryLow,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)

		XCTAssertEqual(risk?.level, .low)
	}

	func testCalculateRisk_IncreasedRisk() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		var summary = summaryHigh
		summary.daysSinceLastExposure = 5
		summary.matchedKeyCount = 10

		// Test the case where preconditions pass and there is increased risk
		let risk = riskCalculation.risk(
			summary: summary,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)

		XCTAssertEqual(risk?.details.daysSinceLastExposure, 5)
		XCTAssertEqual(risk?.level, .increased)
	}

	// MARK: - Risk Level Calculation Error Cases

	func testCalculateRisk_OutsideRangeError_Middle() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// Test the case where preconditions pass and there is increased risk
		// Values below are hand-picked to result in a raw risk score of 5.12 - within a gap in the range
		let summary = makeExposureSummaryContainer(maxRiskScoreFullRange: 128, ad_low: 30, ad_mid: 30, ad_high: 30)
		let risk = riskCalculation.risk(
			summary: summary,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)

		XCTAssertNil(risk)
	}

	func testCalculateRisk_OutsideRangeError_OffHigh() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// Test the case where preconditions pass and there is increased risk
		// Values below are hand-picked to result in a raw risk score of 13.6 - outside of the top range of the config
		let summary = makeExposureSummaryContainer(maxRiskScoreFullRange: 255, ad_low: 40, ad_mid: 40, ad_high: 40)
		let risk = riskCalculation.risk(
			summary: summary,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)

		XCTAssertNil(risk)
	}

	func testCalculateRisk_OutsideRangeError_TooLow() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// Test the case where preconditions pass and there is increased risk
		// Values below are hand-picked to result in a raw risk score of 0.85 - outside of the bottom bound of the config
		let summary = makeExposureSummaryContainer(maxRiskScoreFullRange: 64, ad_low: 10, ad_mid: 10, ad_high: 10)
		let risk = riskCalculation.risk(
			summary: summary,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)

		XCTAssertNil(risk)
	}

	// MARK: - Risk Level Calculation Hierarchy Tests

	// There is a certain order to risk levels, and some override others. This is tested below.

	func testCalculateRisk_IncreasedOverridesUnknownOutdated() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// Test case where last exposure summary was gotten too far in the past,
		// But the risk is increased
		let risk = riskCalculation.risk(
			summary: summaryHigh,
			configuration: appConfig,
			dateLastExposureDetection: Date().addingTimeInterval(.init(days: -2)),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)

		XCTAssertEqual(risk?.level, .increased)
		XCTAssertTrue(risk?.riskLevelHasChanged == false)
	}

	func testCalculateRisk_UnknownInitialOverridesUnknownOutdated() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// Test case where last exposure summary was gotten too far in the past,
		let risk = riskCalculation.risk(
			summary: nil,
			configuration: appConfig,
			dateLastExposureDetection: Date().addingTimeInterval(.init(days: -2)),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)

		XCTAssertEqual(risk?.level, .unknownInitial)
	}

	// MARK: - RiskLevel changed tests

	func testCalculateRisk_RiskChanged_WithPreviousRisk() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// Test the case where we have an old risk level in the store,
		// and the new risk level has changed

		// Will produce increased risk
		let risk = riskCalculation.risk(
			summary: summaryHigh,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: .low,
			providerConfiguration: config
		)
		XCTAssertNotNil(risk)
		XCTAssertEqual(risk?.level, .increased)
		XCTAssertTrue(risk?.riskLevelHasChanged ?? false)
	}

	func testCalculateRisk_RiskChanged_NoPreviousRisk() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// Test the case where we do not have an old risk level in the store,
		// and the new risk level has changed

		// Will produce high risk
		let risk = riskCalculation.risk(
			summary: summaryHigh,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: nil,
			providerConfiguration: config
		)
		// Going from unknown -> increased or low risk does not produce a change
		XCTAssertFalse(risk?.riskLevelHasChanged ?? true)
	}

	func testCalculateRisk_RiskNotChanged() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// Test the case where we have an old risk level in the store,
		// and the new risk level has not changed

		let risk = riskCalculation.risk(
			summary: summaryLow,
			configuration: appConfig,
			// arbitrary, but within limit
			dateLastExposureDetection: Date().addingTimeInterval(-3600),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: .low,
			providerConfiguration: config
		)

		XCTAssertFalse(risk?.riskLevelHasChanged ?? true)
	}

	func testCalculateRisk_LowToUnknown() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// Test the case where we have low risk level in the store,
		// and the new risk calculation returns unknown

		// Produces unknown risk
		let risk = riskCalculation.risk(
			summary: summaryLow,
			configuration: appConfig,
			dateLastExposureDetection: Date().addingTimeInterval(.init(days: -2)),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: .low,
			providerConfiguration: config
		)
		// The risk level did not change - we only care about changes between low and increased
		XCTAssertFalse(risk?.riskLevelHasChanged ?? true)
	}

	func testCalculateRisk_IncreasedToUnknown() {
		let config = RiskProvidingConfiguration(
			exposureDetectionValidityDuration: .init(day: 1),
			exposureDetectionInterval: .init(day: 1),
			detectionMode: .automatic
		)

		// Test the case where we have low risk level in the store,
		// and the new risk calculation returns unknown

		// Produces unknown risk
		let risk = riskCalculation.risk(
			summary: summaryLow,
			configuration: appConfig,
			dateLastExposureDetection: Date().addingTimeInterval(.init(days: -2)),
			activeTracing: .init(interval: 48 * 3600),
			preconditions: preconditions(.valid),
			previousRiskLevel: .increased,
			providerConfiguration: config
		)
		
		// The risk level did not change - we only care about changes between low and increased
		// :BE: we keep the latest risk value and it should be low since we passed summaryLow to the calculation
		// :TODO: improvement in CBA-440

		//XCTAssertFalse(risk?.riskLevelHasChanged ?? true)
		XCTAssertTrue(risk?.riskLevelHasChanged ?? true)
	}
}

// MARK: - Helpers

private extension RiskCalculationTests {

	private var appConfig: SAP_ApplicationConfiguration {
		makeAppConfig(w_low: 1.0, w_med: 0.5, w_high: 0.5)
	}

	private var summaryLow: CodableExposureDetectionSummary {
		makeExposureSummaryContainer(maxRiskScoreFullRange: 80, ad_low: 10, ad_mid: 10, ad_high: 10)
	}

	private var summaryMed: CodableExposureDetectionSummary {
		makeExposureSummaryContainer(maxRiskScoreFullRange: 128, ad_low: 15, ad_mid: 15, ad_high: 15)
	}

	private var summaryHigh: CodableExposureDetectionSummary {
		makeExposureSummaryContainer(maxRiskScoreFullRange: 255, ad_low: 30, ad_mid: 30, ad_high: 30)
	}

	enum PreconditionState {
		case valid
		case invalid
	}

	private func preconditions(_ state: PreconditionState) -> ExposureManagerState {
		switch state {
		case .valid:
			return .init(
				authorized: true,
				enabled: true,
				status:
				.active
			)
		default:
			return .init(authorized: true, enabled: false, status: .disabled)
		}
	}

	private func makeExposureSummaryContainer(
		maxRiskScoreFullRange: Int,
		ad_low: Double,
		ad_mid: Double,
		ad_high: Double
	) -> CodableExposureDetectionSummary {
		.init(
			daysSinceLastExposure: 0,
			matchedKeyCount: 0,
			maximumRiskScore: 0,
			attenuationDurations: [ad_low, ad_mid, ad_high],
			maximumRiskScoreFullRange: maxRiskScoreFullRange
		)
	}

	/// Makes an mock `SAP_ApplicationConfiguration`
	///
	/// Some defaults are applied for ad_norm, w4, and low & high ranges
	private func makeAppConfig(
		ad_norm: Int32 = 25,
		w4: Int32 = 0,
		w_low: Double,
		w_med: Double,
		w_high: Double,
		riskRangeLow: ClosedRange<Int32> = 1...5,
		// Gap between the ranges is on purpose, this is an edge case to test
		riskRangeHigh: Range<Int32> = 6..<11
	) -> SAP_ApplicationConfiguration {
		var config = SAP_ApplicationConfiguration()
		config.attenuationDuration.defaultBucketOffset = w4
		config.attenuationDuration.riskScoreNormalizationDivisor = ad_norm
		config.attenuationDuration.weights.low = w_low
		config.attenuationDuration.weights.mid = w_med
		config.attenuationDuration.weights.high = w_high

		var riskScoreClassLow = SAP_RiskScoreClass()
		riskScoreClassLow.label = "LOW"
		riskScoreClassLow.min = riskRangeLow.lowerBound
		riskScoreClassLow.max = riskRangeLow.upperBound

		var riskScoreClassHigh = SAP_RiskScoreClass()
		riskScoreClassHigh.label = "HIGH"
		riskScoreClassHigh.min = riskRangeHigh.lowerBound
		riskScoreClassHigh.max = riskRangeHigh.upperBound

		config.riskScoreClasses.riskClasses = [
			riskScoreClassLow,
			riskScoreClassHigh
		]

		return config
	}
}
