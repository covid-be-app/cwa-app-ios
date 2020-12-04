//
// 🦠 Corona-Warn-App
//

@testable import ENA
import FMDB
import XCTest

final class DownloadedPackagesSQLLiteStoreTests: XCTestCase {

	private var store: DownloadedPackagesSQLLiteStore = .inMemory()

	override func tearDown() {
		super.tearDown()
		store.close()
	}

	func testEmptyEmptyDb() throws {
		store.open()
		XCTAssertNil(store.package(for: "2020-06-13", region: .belgium))
	}

	// Add a package, try to get it, assert that it matches what we put inside
	func testSettingDays() throws {
		store.open()
		let keysBin = Data("keys".utf8)
		let signature = Data("sig".utf8)

		let package = SAPDownloadedPackage(
			keysBin: keysBin,
			signature: signature
		)
		store.set(region: .belgium, day: "2020-06-12", package: package)
		let packageOut = store.package(for: "2020-06-12", region: .belgium)
		XCTAssertNotNil(packageOut)
		XCTAssertEqual(packageOut?.signature, signature)
		XCTAssertEqual(packageOut?.bin, keysBin)
	}

	// Add a package for a given hour on a given day, try to get it and assert that it matches whatever we put inside
	func testSettingHoursForDay() throws {
		store.open()
		XCTAssertTrue(store.hourlyPackages(for: "2020-06-12", region: .belgium).isEmpty)

		let keysBin = Data("keys".utf8)
		let signature = Data("sig".utf8)

		let package = SAPDownloadedPackage(
			keysBin: keysBin,
			signature: signature
		)
		store.set(region: .belgium, hour: 9, day: "2020-06-12", package: package)
		let hourlyPackagesDE = store.hourlyPackages(for: "2020-06-12", region: .belgium)
		XCTAssertFalse(hourlyPackagesDE.isEmpty)

		store.set(region: .europeanUnion, hour: 9, day: "2020-06-12", package: package)
		let hourlyPackagesIT = store.hourlyPackages(for: "2020-06-12", region: .europeanUnion)
		XCTAssertFalse(hourlyPackagesIT.isEmpty)
	}

	// Add a package for a given hour on a given day, try to get it and assert that it matches whatever we put inside
	func testHoursAreDeletedIfDayIsAdded() throws {
		store.open()
		XCTAssertTrue(store.hourlyPackages(for: "2020-06-12", region: .belgium).isEmpty)

		let keysBin = Data("keys".utf8)
		let signature = Data("sig".utf8)

		let package = SAPDownloadedPackage(
			keysBin: keysBin,
			signature: signature
		)

		// Add hours
		store.set(region: .belgium, hour: 1, day: "2020-06-12", package: package)
		store.set(region: .belgium, hour: 2, day: "2020-06-12", package: package)
		store.set(region: .belgium, hour: 3, day: "2020-06-12", package: package)
		store.set(region: .belgium, hour: 4, day: "2020-06-12", package: package)
		store.set(region: .europeanUnion, hour: 1, day: "2020-06-12", package: package)
		store.set(region: .europeanUnion, hour: 2, day: "2020-06-12", package: package)

		// Assert that hours exist
		let hourlyPackagesDE = store.hourlyPackages(for: "2020-06-12", region: .belgium)
		XCTAssertEqual(hourlyPackagesDE.count, 4)

		let hourlyPackagesIT = store.hourlyPackages(for: "2020-06-12", region: .europeanUnion)
		XCTAssertEqual(hourlyPackagesIT.count, 2)

		// Now add a full day
		store.set(region: .belgium, day: "2020-06-12", package: package)
		XCTAssertTrue(store.hourlyPackages(for: "2020-06-12", region: .belgium).isEmpty)

		store.set(region: .europeanUnion, day: "2020-06-12", package: package)
		XCTAssertTrue(store.hourlyPackages(for: "2020-06-12", region: .europeanUnion).isEmpty)
	}

	func test_ResetRemovesAllKeys() throws {
		let database = FMDatabase.inMemory()
		let store = DownloadedPackagesSQLLiteStore(database: database, migrator: SerialMigratorFake(), latestVersion: 0)
		store.open()

		let keysBin = Data("keys".utf8)
		let signature = Data("sig".utf8)

		let package = SAPDownloadedPackage(
			keysBin: keysBin,
			signature: signature
		)

		// Add days
		store.set(region: .belgium, day: "2020-06-01", package: package)
		store.set(region: .belgium, day: "2020-06-02", package: package)
		store.set(region: .belgium, day: "2020-06-03", package: package)
		store.set(region: .europeanUnion, day: "2020-06-03", package: package)
		store.set(region: .belgium, day: "2020-06-04", package: package)
		store.set(region: .belgium, day: "2020-06-05", package: package)
		store.set(region: .belgium, day: "2020-06-06", package: package)
		store.set(region: .europeanUnion, day: "2020-06-06", package: package)
		store.set(region: .belgium, day: "2020-06-07", package: package)

		XCTAssertEqual(store.allDays(region: .belgium).count, 7)
		XCTAssertEqual(store.allDays(region: .europeanUnion).count, 2)

		store.reset()
		store.open()

		XCTAssertEqual(store.allDays(region: .belgium).count, 0)
		XCTAssertEqual(store.allDays(region: .europeanUnion).count, 0)
		XCTAssertEqual(database.lastErrorCode(), 0)
	}
	
	func test_deleteDayPackage() throws {
		store.open()

		let keysBin = Data("keys".utf8)
		let signature = Data("sig".utf8)

		let package = SAPDownloadedPackage(
			keysBin: keysBin,
			signature: signature
		)
		
		let regions = [BERegion.belgium, BERegion.europeanUnion]
		let days = ["2020-11-03", "2020-11-02", "2020-11-01", "2020-10-31", "2020-10-30", "2020-10-29", "2020-10-28", "2020-10-27"]

		// Add days DE, IT
		for region in regions {
			for date in days {
				store.set(region: region, day: date, package: package)
			}
		}

		// delete the packages one by one
		for region in regions {
			XCTAssertEqual(store.allDays(region: region).count, days.count)
			var deleteCounter = 0
			for date in days {
				store.deleteDayPackage(for: date, region: region)
				deleteCounter += 1
				XCTAssertEqual(store.allDays(region: region).count, days.count - deleteCounter)
			}
		}
	}
	
	func test_deleteHourPackage() throws {
		store.open()

		let keysBin = Data("keys".utf8)
		let signature = Data("sig".utf8)

		let package = SAPDownloadedPackage(
			keysBin: keysBin,
			signature: signature
		)

		let regions = [BERegion.belgium, BERegion.europeanUnion]
		let days = ["2020-11-03", "2020-11-02"]
		let hours = [Int].init(1...24)

		// Add days DE, IT
		for region in regions {
			for date in days {
				for hour in hours {
					store.set(region: region, hour: hour, day: date, package: package)
				}
			}
		}
		// delete the packages one by one
		for region in regions {
			for date in days {
				var deleteCounter = 0
				for hour in hours {
					store.deleteHourPackage(for: date, hour: hour, region: region)
					deleteCounter += 1
					XCTAssertEqual(store.hours(for: date, region: region).count, hours.count - deleteCounter)
				}
			}
		}
	}

	func test_deleteWithCloseOpenDB() throws {
		let unitTestStore: DownloadedPackagesStore = DownloadedPackagesSQLLiteStore(fileName: "unittest")

		unitTestStore.open()

		let keysBin = Data("keys".utf8)
		let signature = Data("sig".utf8)

		let package = SAPDownloadedPackage(
			keysBin: keysBin,
			signature: signature
		)

		unitTestStore.set(region: .belgium, hour: 1, day: "2020-11-04", package: package)
		unitTestStore.set(region: .belgium, hour: 2, day: "2020-11-04", package: package)
		unitTestStore.set(region: .belgium, day: "2020-11-03", package: package)
		unitTestStore.set(region: .belgium, day: "2020-11-02", package: package)
		
		XCTAssertEqual(unitTestStore.hourlyPackages(for: "2020-11-04", region: .belgium).count, 2)
		XCTAssertEqual(unitTestStore.hours(for: "2020-11-04", region: .belgium).count, 2)
		XCTAssertNotNil(unitTestStore.package(for: "2020-11-03", region: .belgium))
		XCTAssertNotNil(unitTestStore.package(for: "2020-11-02", region: .belgium))
		
		unitTestStore.deleteDayPackage(for: "2020-11-02", region: BERegion.belgium)
		unitTestStore.deleteHourPackage(for: "2020-11-04", hour: 1, region: .belgium)
		
		unitTestStore.close()
		unitTestStore.open()

		XCTAssertEqual(unitTestStore.hours(for: "2020-11-04", region: .belgium).count, 1)
		unitTestStore.deleteHourPackage(for: "2020-11-04", hour: 2, region: .belgium)
		XCTAssertEqual(unitTestStore.hours(for: "2020-11-04", region: .belgium).count, 0)
		
		XCTAssertNotNil(unitTestStore.package(for: "2020-11-03", region: .belgium))
		unitTestStore.deleteDayPackage(for: "2020-11-03", region: .belgium)
		XCTAssertNil(unitTestStore.package(for: "2020-11-03", region: .belgium))
	}
}
