//
// 🦠 Corona-Warn-App
//

import Foundation
import FMDB

protocol DownloadedPackagesStoreV1: AnyObject {
	func open()
	func close()

	@discardableResult
	func set(
		region: BERegion,
		day: String,
		package: SAPDownloadedPackage
	) -> Result<Void, SQLiteErrorCode>

	@discardableResult
	func set(
		region: BERegion,
		hour: Int,
		day: String,
		package: SAPDownloadedPackage
	) -> Result<Void, SQLiteErrorCode>
	
	func package(for day: String, region: BERegion) -> SAPDownloadedPackage?
	func hourlyPackages(for day: String, region: BERegion) -> [SAPDownloadedPackage]
	func allDays(region: BERegion) -> [String] // 2020-05-30
	func hours(for day: String, region: BERegion) -> [Int]
	func reset()
	func deleteOutdatedDays(now: String) throws

	func deleteDayPackage(for day: String, region: BERegion)
	func deleteHourPackage(for day: String, hour: Int, region: BERegion)
	
	#if !RELEASE

	var keyValueStore: Store? { get set }

	#endif
}
