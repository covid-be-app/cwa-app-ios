//
// 🦠 Corona-Warn-App
//

import FMDB

protocol SerialMigratorProtocol {
	func migrate() throws
}

final class SerialMigrator: SerialMigratorProtocol {

	private let latestVersion: Int
	private let database: FMDatabase
	private let migrations: [Migration]

	init(
		latestVersion: Int,
		database: FMDatabase,
		migrations: [Migration]
	) {
		self.latestVersion = latestVersion
		self.database = database
		self.migrations = migrations
	}

	func migrate() throws {
		if database.userVersion < latestVersion {
			let userVersion = Int(database.userVersion)
			
			log(message: "Migrating database from v\(userVersion) to v\(latestVersion)!")

			do {
				try migrations[userVersion].execute()
				self.database.userVersion += 1
				try migrate()
			} catch {
				log(message: "Migration failed from version \(database.userVersion) to version \(database.userVersion.advanced(by: 1))", level: .error)
				throw error
			}
		} else {
			log(message: "No database migration needed.")
		}
	}
}
