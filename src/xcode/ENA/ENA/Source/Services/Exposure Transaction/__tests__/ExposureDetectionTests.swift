//
// Corona-Warn-App
//
// SAP SE and all other contributors
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
@testable import ENA
import ExposureNotification
import OpenCombine

final class ExposureDetectionTransactionTests: XCTestCase {

	func testGivenThatEveryNeedIsSatisfiedTheDetectionFinishes() throws {
		let delegate = ExposureDetectionDelegateMock()
		var availableDataExpectations: [BERegion: XCTestExpectation] = [:]
		var downloadDeltaExpectations: [BERegion: XCTestExpectation] = [:]
		var downloadAndStoreExpectations: [BERegion: XCTestExpectation] = [:]
		var writtenPackagesExpectations: [BERegion: XCTestExpectation] = [:]

		var allExpectations: [XCTestExpectation] = []
		var writtenPackagesExpectationsArray: [XCTestExpectation] = []

		BERegion.allCases.forEach { region in
			let availableDataToBeCalled = expectation(description: "availableData called for \(region.rawValue)")
			let downloadDeltaToBeCalled = expectation(description: "downloadDelta called for \(region.rawValue)")
			let downloadAndStoreToBeCalled = expectation(description: "downloadAndStore called for \(region.rawValue)")
			let writtenPackagesBeCalled = expectation(description: "writtenPackages called for \(region.rawValue)")

			availableDataExpectations[region] = availableDataToBeCalled
			downloadDeltaExpectations[region] = downloadDeltaToBeCalled
			downloadAndStoreExpectations[region] = downloadAndStoreToBeCalled
			writtenPackagesExpectations[region] = writtenPackagesBeCalled
			
			allExpectations.append(availableDataToBeCalled)
			allExpectations.append(downloadDeltaToBeCalled)
			allExpectations.append(downloadAndStoreToBeCalled)
		}
		
		BERegion.allCases.forEach { region in
			writtenPackagesExpectationsArray.append(writtenPackagesExpectations[region]!)
		}
		delegate.availableData = { region -> DaysAndHours? in
			availableDataExpectations[region]!.fulfill()
			return (days: ["2020-05-01"], hours: [])
		}

		delegate.downloadDelta = { available, region in
			downloadDeltaExpectations[region]!.fulfill()
			return (days: ["2020-05-01"], hours: [])
		}

		delegate.downloadAndStore = { delta, region in
			downloadAndStoreExpectations[region]!.fulfill()
			return nil
		}

		let rootDir = FileManager().temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
		try FileManager().createDirectory(atPath: rootDir.path, withIntermediateDirectories: true, attributes: nil)
		let url0 = rootDir.appendingPathComponent("1").appendingPathExtension("sig")
		let url1 = rootDir.appendingPathComponent("1").appendingPathExtension("bin")
		try "url0".write(to: url0, atomically: true, encoding: .utf8)
		try "url1".write(to: url1, atomically: true, encoding: .utf8)

		let writtenPackages = WrittenPackages(urls: [url0, url1])

		delegate.writtenPackages = { region in
			writtenPackagesExpectations[region]!.fulfill()
			return writtenPackages
		}

		let summaryResultBeCalled = expectation(description: "summaryResult called")
		delegate.summaryResult = { _, _ in
			summaryResultBeCalled.fulfill()
			return .success(MutableENExposureDetectionSummary(daysSinceLastExposure: 5))
		}

		let startCompletionCalled = expectation(description: "start completion called")
		let detection = ExposureDetection(configuration: ENExposureConfiguration(), delegate: delegate)
		detection.start { _ in
			startCompletionCalled.fulfill()
		}

		wait(
			for: allExpectations + writtenPackagesExpectationsArray + [summaryResultBeCalled, startCompletionCalled],
			timeout: 1.0,
			enforceOrder: true
		)
	}
	
	func testDeleteTemporaryDirectoryContents() throws {
		let fileManager = FileManager.default
		let fileContents = "XXXXXX"
		let data = fileContents.data(using: .utf8)!

		try fileManager.removeTemporaryDirectoryContents()
		for x in 0..<20 {
			let directoryURL = fileManager.temporaryDirectory.appendingPathComponent("dir\(x)")
			let fileURL = directoryURL.appendingPathComponent("file\(x).bin")
			try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: false, attributes: nil)
			try data.write(to: fileURL)
		}

		let preDeleteItems = try fileManager.contentsOfDirectory(at: fileManager.temporaryDirectory, includingPropertiesForKeys: nil)
		XCTAssertFalse(preDeleteItems.isEmpty)

		let delegate = ExposureDetectionDelegateMock()

		delegate.availableData = { region -> DaysAndHours? in
			return (days: ["2020-05-01"], hours: [])
		}

		delegate.downloadDelta = { available, region in
			return (days: ["2020-05-01"], hours: [])
		}

		delegate.downloadAndStore = { delta, region in
			return nil
		}

		let rootDir = FileManager().temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
		try FileManager().createDirectory(atPath: rootDir.path, withIntermediateDirectories: true, attributes: nil)
		let url0 = rootDir.appendingPathComponent("1").appendingPathExtension("sig")
		let url1 = rootDir.appendingPathComponent("1").appendingPathExtension("bin")
		try "url0".write(to: url0, atomically: true, encoding: .utf8)
		try "url1".write(to: url1, atomically: true, encoding: .utf8)

		let writtenPackages = WrittenPackages(urls: [url0, url1])

		delegate.writtenPackages = { region in
			return writtenPackages
		}

		delegate.summaryResult = { _, _ in
			return .success(MutableENExposureDetectionSummary(daysSinceLastExposure: 5))
		}

		let startCompletionCalled = expectation(description: "start completion called")
		let detection = ExposureDetection(configuration: .mock(), delegate: delegate)
		detection.start { _ in
			do {
				let items = try fileManager.contentsOfDirectory(at: fileManager.temporaryDirectory, includingPropertiesForKeys: nil)
				XCTAssertTrue(items.isEmpty)
			} catch {
				XCTAssert(false)
			}
			startCompletionCalled.fulfill()
		}

		wait(
			for: [startCompletionCalled],
			timeout: 1.0,
			enforceOrder: true
		)
	}
}

final class MutableENExposureDetectionSummary: ENExposureDetectionSummary {
	init(daysSinceLastExposure: Int = 0, matchedKeyCount: UInt64 = 0, maximumRiskScore: ENRiskScore = .zero, attenuationDurations: [NSNumber] = [], metadata: [AnyHashable: Any]? = nil) {
		self._daysSinceLastExposure = daysSinceLastExposure
		self._matchedKeyCount = matchedKeyCount
		self._maximumRiskScore = maximumRiskScore
		self._attenuationDurations = attenuationDurations
		self._metadata = metadata
	}

	private var _daysSinceLastExposure: Int
	override var daysSinceLastExposure: Int {
		_daysSinceLastExposure
	}

	private var _matchedKeyCount: UInt64
	override var matchedKeyCount: UInt64 {
		_matchedKeyCount
	}

	private var _maximumRiskScore: ENRiskScore
	override var maximumRiskScore: ENRiskScore { _maximumRiskScore }
	
	private var _attenuationDurations: [NSNumber]
	override var attenuationDurations: [NSNumber] { _attenuationDurations }
	
	private var _metadata: [AnyHashable: Any]?
	override var metadata: [AnyHashable: Any]? { _metadata }
}

private final class ExposureDetectionDelegateMock {
	// MARK: Types
	struct SummaryError: Error { }
	typealias DownloadAndStoreHandler = (_ delta: DaysAndHours, _ region: BERegion) -> Error?

	// MARK: Properties
	var availableData: (_ region: BERegion) -> DaysAndHours? = { region in
		nil
	}

	var downloadDelta: (_ available: DaysAndHours, _ region: BERegion) -> DaysAndHours = { _, _ in
		DaysAndHours(days: [], hours: [])
	}

	var downloadAndStore: DownloadAndStoreHandler = { _, _ in nil }

	var writtenPackages: (_ region: BERegion) -> WrittenPackages? = { _ in
		nil
	}

	var summaryResult: (
		_ configuration: ENExposureConfiguration,
		_ writtenPackages: WrittenPackages
		) -> Result<ENExposureDetectionSummary, Error> = { _, _ in
		.failure(SummaryError())
	}
}

extension ExposureDetectionDelegateMock: ExposureDetectionDelegate {
	func exposureDetectionDetermineAvailableData(_ detection: ExposureDetection, region: BERegion) -> Future<DaysAndHours?, Error> {
		return Future<DaysAndHours?, Error>.withResult(availableData(region))
	}
	
	func exposureDetection(_ detection: ExposureDetection, downloadDeltaFor remote: DaysAndHours, region: BERegion) -> DaysAndHours {
		downloadDelta(remote, region)
	}
	
	func exposureDetection(_ detection: ExposureDetection, downloadAndStore delta: DaysAndHours, region: BERegion, completion: @escaping (Error?) -> Void) {
		completion(downloadAndStore(delta, region))

	}

	func exposureDetectionWriteDownloadedPackages(_ detection: ExposureDetection, region: BERegion) -> WrittenPackages? {
		writtenPackages(region)
	}

	func exposureDetection(_ detection: ExposureDetection, detectSummaryWithConfiguration configuration: ENExposureConfiguration, writtenPackages: WrittenPackages, completion: @escaping (Result<ENExposureDetectionSummary, Error>) -> Void) {
		completion(summaryResult(configuration, writtenPackages))
	}
}

private extension ENExposureConfiguration {
	class func mock() -> ENExposureConfiguration {
		let config = ENExposureConfiguration()
		config.metadata = ["attenuationDurationThresholds": [50, 70]]
		config.attenuationLevelValues = [1, 2, 3, 4, 5, 6, 7, 8]
		config.daysSinceLastExposureLevelValues = [1, 2, 3, 4, 5, 6, 7, 8]
		config.durationLevelValues = [1, 2, 3, 4, 5, 6, 7, 8]
		config.transmissionRiskLevelValues = [1, 2, 3, 4, 5, 6, 7, 8]
		return config
	}
}

final class MutableENExposureWindow: ENExposureWindow {

	init(
		calibrationConfidence: ENCalibrationConfidence = .lowest,
		date: Date = Date(),
		diagnosisReportType: ENDiagnosisReportType = .unknown,
		infectiousness: ENInfectiousness = .none,
		scanInstances: [ENScanInstance] = []
	) {
		self._calibrationConfidence = calibrationConfidence
		self._date = date
		self._diagnosisReportType = diagnosisReportType
		self._infectiousness = infectiousness
		self._scanInstances = scanInstances
	}

	private var _calibrationConfidence: ENCalibrationConfidence
	override var calibrationConfidence: ENCalibrationConfidence {
		_calibrationConfidence
	}

	private var _date: Date
	override var date: Date {
		_date
	}

	private var _diagnosisReportType: ENDiagnosisReportType
	override var diagnosisReportType: ENDiagnosisReportType {
		_diagnosisReportType
	}

	private var _infectiousness: ENInfectiousness
	override var infectiousness: ENInfectiousness {
		_infectiousness
	}

	private var _scanInstances: [ENScanInstance]
	override var scanInstances: [ENScanInstance] {
		_scanInstances
	}
}
