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
		let testId = BEMobileTestId(datePatientInfectious: "2020-07-22")
		store.mobileTestId = testId
		
		let loadedId = store.mobileTestId!
		XCTAssertEqual(loadedId.fullString, testId.fullString)
    }
	
	func testStoreTestResult() throws {
		let result = TestResult.positive
		
		store.testResult = result
		
		let loadedResult = store.testResult!
		XCTAssertEqual(loadedResult.dateSampleCollected,result.dateSampleCollected)
	}
	
	func testStoreTestIdDeletionTime() throws {
		let timeInterval:TimeInterval = 300
		XCTAssertEqual(store.deleteMobileTestIdAfterTimeInterval,14*60*60*24)
		store.deleteMobileTestIdAfterTimeInterval = timeInterval
		XCTAssertEqual(store.deleteMobileTestIdAfterTimeInterval,timeInterval)

	}
}
