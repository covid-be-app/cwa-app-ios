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

class BEStoreTests: XCTestCase {
	private var store: SecureStore!

	override func setUp() {
		store = SecureStore(at: URL(staticString: ":memory:"), key: "123456")
	}

    func testStoreMobileTestId() throws {
		let testId = BeMobileTestId(timePatientInfectious: "2020-07-22")
		store.mobileTestIds = [testId]
		
		XCTAssertEqual(store.mobileTestIds!.count, 1)
		let loadedId = store.mobileTestIds![0]
		XCTAssertEqual(loadedId.fullString, testId.fullString)
    }
}
