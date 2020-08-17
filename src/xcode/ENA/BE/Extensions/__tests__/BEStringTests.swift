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

class BEStringTests: XCTestCase {

    func testRandom() throws {
		let randomString = String.random(length:10)
		
		XCTAssertEqual(
			randomString.count,
			10
		)
    }
	
	func testSubstrig() throws {
		let string = "1234567890"
		let first = string[0..<4]
		let middle = string[5..<7]
		
		XCTAssertEqual(
			first.count,
			4
		)

		XCTAssertEqual(
			first[0],
			"1"
		)

		XCTAssertEqual(
			middle.count,
			2
		)

		XCTAssertEqual(
			middle[0],
			"6"
		)
	}

}
