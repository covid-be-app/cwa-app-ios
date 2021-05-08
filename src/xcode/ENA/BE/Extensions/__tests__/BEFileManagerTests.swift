//
// Coronalert
//
// Devside and all other contributors
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

class BEFileManagerTests: XCTestCase {

    func testDeleteContentsOfTemporaryFolder() throws {
		let fileManager = FileManager.default
		let fileContents = "XXXXXX"
		let data = fileContents.data(using: .utf8)!

		for x in 0..<20 {
			let directoryURL = fileManager.temporaryDirectory.appendingPathComponent("dir\(x)")
			let fileURL = directoryURL.appendingPathComponent("file\(x).bin")
			try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: false, attributes: nil)
			try data.write(to: fileURL)
		}

		let preDeleteItems = try fileManager.contentsOfDirectory(at: fileManager.temporaryDirectory, includingPropertiesForKeys: nil)
		XCTAssertFalse(preDeleteItems.isEmpty)

		try fileManager.removeTemporaryDirectoryContents()
		
		let items = try fileManager.contentsOfDirectory(at: fileManager.temporaryDirectory, includingPropertiesForKeys: nil)
		XCTAssertTrue(items.isEmpty)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
