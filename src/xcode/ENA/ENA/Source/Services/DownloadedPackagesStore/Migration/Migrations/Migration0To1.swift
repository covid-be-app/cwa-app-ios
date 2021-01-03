//
// 🦠 Corona-Warn-App
//

import FMDB

final class Migration0To1: Migration {

	private let database: FMDatabase

	init(database: FMDatabase) {
		self.database = database
	}

	func execute() throws {
		let sql = """
			BEGIN TRANSACTION;

			ALTER
				TABLE Z_DOWNLOADED_PACKAGE
			ADD
				Z_REGION INTEGER;

			UPDATE
				Z_DOWNLOADED_PACKAGE
			SET
				Z_REGION = "BE";

			ALTER TABLE
				Z_DOWNLOADED_PACKAGE
			RENAME TO
				Z_DOWNLOADED_PACKAGE_OLD;

			PRAGMA locking_mode=EXCLUSIVE;
			PRAGMA auto_vacuum=2;
			PRAGMA journal_mode=WAL;

			CREATE TABLE
				Z_DOWNLOADED_PACKAGE (
				Z_BIN BLOB NOT NULL,
				Z_SIGNATURE BLOB NOT NULL,
				Z_DAY TEXT NOT NULL,
				Z_HOUR INTEGER,
				Z_REGION STRING NOT NULL,
				PRIMARY KEY (
					Z_REGION,
					Z_DAY,
					Z_HOUR
				)
			);

			INSERT INTO
				Z_DOWNLOADED_PACKAGE
			SELECT * FROM
				Z_DOWNLOADED_PACKAGE_OLD;

			UPDATE
				Z_DOWNLOADED_PACKAGE
			SET
				Z_REGION = "BE";

			DROP
				TABLE Z_DOWNLOADED_PACKAGE_OLD;

			COMMIT;
		"""

		guard database.executeStatements(sql) else {
			throw MigrationError.general(description: "(\(database.lastErrorCode())) \(database.lastErrorMessage())")
		}
	}
}
