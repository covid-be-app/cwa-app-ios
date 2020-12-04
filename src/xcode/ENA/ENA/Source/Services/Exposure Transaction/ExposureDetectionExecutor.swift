//
// Created by Hu, Hao on 06.06.20.
// Copyright (c) 2020 SAP SE. All rights reserved.
//
// Modified by Devside SRL
//

import Foundation
import ExposureNotification
import Combine

final class ExposureDetectionExecutor: ExposureDetectionDelegate {
	private let client: Client
	private let downloadedPackagesStore: DownloadedPackagesStore
	private let store: Store
	private let exposureDetector: ExposureDetector

	init(
		client: Client,
		downloadedPackagesStore: DownloadedPackagesStore,
		store: Store,
		exposureDetector: ExposureDetector
	) {

		self.client = client
		self.downloadedPackagesStore = downloadedPackagesStore
		self.store = store
		self.exposureDetector = exposureDetector
	}

	func exposureDetectionDetermineAvailableData(
		_ detection: ExposureDetection,
		region: BERegion
	) -> Future<DaysAndHours?, Error> {
		
		return Future { promise in
			self.client.availableDays(region: region) { result in
				switch result {
				case let .success(days):
					self.client.availableHours(day: .formattedToday(), region: region) { result in
						switch result {
						case let .success(hours):
							promise(.success((days: days, hours: hours)))
						case .failure:
							promise(.success(nil))
						}
					}
				case .failure:
					promise(.success(nil))
				}
			}
		}
	}

	func exposureDetection(_ detection: ExposureDetection, downloadDeltaFor remote: DaysAndHours, region: BERegion) -> DaysAndHours {
		// prune the store
		try? downloadedPackagesStore.deleteOutdatedDays(now: .formattedToday())
		
		let delta = DeltaCalculationResult(
			remoteDays: Set(remote.days),
			remoteHours: Set(remote.hours),
			localDays: Set(downloadedPackagesStore.allDays(region: region)),
			localHours: Set(downloadedPackagesStore.hours(for: .formattedToday(), region: region))
		)
		return (
			days: Array(delta.missingDays),
			hours: Array(delta.missingHours)
		)
	}

	func exposureDetection(_ detection: ExposureDetection, downloadAndStore delta: DaysAndHours, region: BERegion, completion: @escaping (Error?) -> Void) {
		func storeDaysAndHours(_ fetchedDaysAndHours: FetchedDaysAndHours) {
			downloadedPackagesStore.addFetchedDaysAndHours(fetchedDaysAndHours, region: region)
			completion(nil)
		}
		client.fetchDays(
				delta.days,
				hours: delta.hours,
				of: .formattedToday(),
				region: region,
				completion: storeDaysAndHours
		)
	}

	func exposureDetection(_ detection: ExposureDetection, downloadConfiguration completion: @escaping (ENExposureConfiguration?) -> Void) {
		client.exposureConfiguration(completion: completion)
	}

	func exposureDetectionWriteDownloadedPackages(_ detection: ExposureDetection, region: BERegion) -> WrittenPackages? {
		let fileManager = FileManager()
		let rootDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
		do {
			try fileManager.createDirectory(at: rootDir, withIntermediateDirectories: true, attributes: nil)
			
			// :BE: remove unused parameters
			let packages = downloadedPackagesStore.allPackages(region: region)
			let writer = AppleFilesWriter(rootDir: rootDir, keyPackages: packages)
			return writer.writeAllPackages()
		} catch {
			return nil
		}
	}

	func exposureDetection(
			_ detection: ExposureDetection,
			detectSummaryWithConfiguration
			configuration: ENExposureConfiguration,
			writtenPackages: WrittenPackages,
			completion: @escaping (Result<ENExposureDetectionSummary, Error>) -> Void
	) {
		func withResultFrom(
				summary: ENExposureDetectionSummary?,
				error: Error?
		) -> Result<ENExposureDetectionSummary, Error> {
			if let error = error {
				return .failure(error)
			}
			if let summary = summary {
				return .success(summary)
			}
			fatalError("invalid state")
		}
		_ = exposureDetector.detectExposures(
				configuration: configuration,
				diagnosisKeyURLs: writtenPackages.urls
		) { summary, error in
			completion(withResultFrom(summary: summary, error: error))
		}
	}

}

extension DownloadedPackagesStore {
	func addFetchedDaysAndHours(_ daysAndHours: FetchedDaysAndHours, region: BERegion) {
		let days = daysAndHours.days
		days.bucketsByDay.forEach { day, bucket in
			self.set(region: region, day: day, package: bucket)
		}

		let hours = daysAndHours.hours
		hours.bucketsByHour.forEach { hour, bucket in
			self.set(region: region, hour: hour, day: hours.day, package: bucket)
		}
	}
}

private extension DownloadedPackagesStore {
	func allPackages(region: BERegion) -> [SAPDownloadedPackage] {
		var packages = [SAPDownloadedPackage]()
		let fullDays = allDays(region: region)
		packages.append(
			contentsOf: fullDays.map { package(for: $0, region: region) }.compactMap { $0 }
		)

		let allHoursForToday = hourlyPackages(for: .formattedToday(), region: region)
		packages.append(contentsOf: allHoursForToday)

		return packages
	}
}
