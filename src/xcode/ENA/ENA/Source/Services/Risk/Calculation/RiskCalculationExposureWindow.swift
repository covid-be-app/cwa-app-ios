//
// 🦠 Corona-Warn-App
//

import Foundation
import ExposureNotification

/// Determines the risk level for one exposure window
/// https://github.com/corona-warn-app/cwa-app-tech-spec/blob/7779cabcff42afb437f743f1d9e35592ef989c52/docs/spec/exposure-windows.md#determine-risk-level-for-exposure-windows
final class RiskCalculationExposureWindow: Codable, CustomDebugStringConvertible {

	// MARK: - Init

	init(
		exposureWindow: ExposureWindow,
		configuration: RiskCalculationConfiguration
	) {
		self.exposureWindow = exposureWindow
		self.configuration = configuration
	}

	// MARK: - CustomDebugStringConvertible

	var debugDescription: String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .iso8601

		if let data = try? encoder.encode(self),
		   let jsonString = String(data: data, encoding: .utf8) {
			return jsonString
		}

		return String(describing: Self.self)
	}

	// MARK: - Protocol Codable

	enum CodingKeys: String, CodingKey {
		case exposureWindow, configuration, isDroppedByMinutesAtAttenuation, transmissionRiskLevel, isDroppedByTransmissionRiskLevel, transmissionRiskValue, weightedMinutes, normalizedTime, riskLevel
	}

	convenience init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let exposureWindow = try container.decode(ExposureWindow.self, forKey: .exposureWindow)
		let configuration = try container.decode(RiskCalculationConfiguration.self, forKey: .configuration)

		self.init(exposureWindow: exposureWindow, configuration: configuration)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(exposureWindow, forKey: .exposureWindow)
		try container.encode(configuration, forKey: .configuration)

		// Additional values are encoded to show them in the developer menu
		try container.encode(isDroppedByMinutesAtAttenuation, forKey: .isDroppedByMinutesAtAttenuation)
		try container.encode(transmissionRiskLevel, forKey: .transmissionRiskLevel)
		try container.encode(isDroppedByTransmissionRiskLevel, forKey: .isDroppedByTransmissionRiskLevel)
		try container.encode(transmissionRiskValue, forKey: .transmissionRiskValue)
		try container.encode(weightedMinutes, forKey: .weightedMinutes)
		try container.encode(normalizedTime, forKey: .normalizedTime)
		try container.encode(riskLevel, forKey: .riskLevel)
	}

	// MARK: - Internal
	
	private(set) var exposureWindow: ExposureWindow

	var calibrationConfidence: ENCalibrationConfidence {
		exposureWindow.calibrationConfidence
	}

	var date: Date {
		exposureWindow.date
	}

	var reportType: ENDiagnosisReportType {
		exposureWindow.reportType
	}

	var infectiousness: ENInfectiousness {
		exposureWindow.infectiousness
	}

	var scanInstances: [ScanInstance] {
		exposureWindow.scanInstances
	}

	/// 1. Filter by `Minutes at Attenuation`
	lazy var isDroppedByMinutesAtAttenuation: Bool = {
		configuration.minutesAtAttenuationFilters
			.map { filter in
				let secondsAtAttenuation = exposureWindow.scanInstances
					.filter { $0.secondsSinceLastScan >= 0 }
					.filter { scanInstance in
						filter.attenuationRange.contains(scanInstance.minAttenuation)
					}
					.map { $0.secondsSinceLastScan }
					.reduce(0, +)

				let minutesAtAttenuation = secondsAtAttenuation / 60

				return filter.dropIfMinutesInRange.contains(minutesAtAttenuation)
			}
			.contains(true)
	}()

	/// 2. Determine `Transmission Risk Level`
	lazy var transmissionRiskLevel: Int = {
		let infectiousnessOffset = exposureWindow.infectiousness == .high ?
			configuration.trlEncoding.infectiousnessOffsetHigh :
			configuration.trlEncoding.infectiousnessOffsetStandard

		var reportTypeOffset: Int
		switch exposureWindow.reportType {
		case .confirmedTest:
			reportTypeOffset = configuration.trlEncoding.reportTypeOffsetConfirmedTest
		case .confirmedClinicalDiagnosis:
			reportTypeOffset = configuration.trlEncoding.reportTypeOffsetConfirmedClinicalDiagnosis
		case .selfReported:
			reportTypeOffset = configuration.trlEncoding.reportTypeOffsetSelfReport
		case .recursive:
			reportTypeOffset = configuration.trlEncoding.reportTypeOffsetRecursive
		default:
			reportTypeOffset = 0
		}

		return infectiousnessOffset + reportTypeOffset
	}()

	/// 3. Filter by `Transmission Risk Level`
	lazy var isDroppedByTransmissionRiskLevel: Bool = {
		configuration.trlFilters
			.map { $0.dropIfTrlInRange.contains(transmissionRiskLevel) }
			.contains(true)
	}()

	/// 6. Determine `Normalized Time`
	lazy var normalizedTime: Double = {
		transmissionRiskValue * weightedMinutes
	}()

	/// 7. Determine `Risk Level`
	lazy var riskLevel: ENFRiskLevel? = {
		configuration.normalizedTimePerEWToRiskLevelMapping
			.first { $0.normalizedTimeRange.contains(normalizedTime) }
			.map { $0.riskLevel }
	}()

	// MARK: - Private

	private let configuration: RiskCalculationConfiguration

	/// 4. Determine `Transmission Risk Value`
	private lazy var transmissionRiskValue: Double = {
		configuration.transmissionRiskValueMapping
			.first { $0.transmissionRiskLevel == transmissionRiskLevel }
			.map { $0.transmissionRiskValue } ?? 0
	}()

	/// 5. Determine `Weighted Minutes`
	private lazy var weightedMinutes: Double = {
		return exposureWindow.scanInstances
			.filter { $0.secondsSinceLastScan >= 0 }
			.map { scanInstance in
				let weight = configuration.minutesAtAttenuationWeights
					.first { $0.attenuationRange.contains(scanInstance.minAttenuation) }
					.map { $0.weight } ?? 0

				return Double(scanInstance.secondsSinceLastScan) * weight
			}.reduce(0, +) / 60
	}()

}
