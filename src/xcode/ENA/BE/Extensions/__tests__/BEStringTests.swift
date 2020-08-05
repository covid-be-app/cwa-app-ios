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

	func testFromDateWithoutTime() throws {
        let date = Date()
		let string = String.fromDateWithoutTime(date:date)
		let stringComponents = string.split(separator:"-")
		
		XCTAssertEqual(
			stringComponents.count,
			3
		)

		XCTAssertEqual(
			stringComponents[0].count,
			4
		)

		XCTAssertEqual(
			stringComponents[1].count,
			2
		)

		XCTAssertEqual(
			stringComponents[2].count,
			2
		)
    }
	
	func testDateWithoutTime() throws {
		let string = String("2020-05-10")
		let date = string.dateWithoutTime!
		let yearFormatter = DateFormatter()
		yearFormatter.dateFormat = "YYYY"
		let monthFormatter = DateFormatter()
		monthFormatter.dateFormat = "MM"
		let dayFormatter = DateFormatter()
		dayFormatter.dateFormat = "dd"

		XCTAssertEqual(
			yearFormatter.string(from: date),
			"2020"
		)

		XCTAssertEqual(
			monthFormatter.string(from: date),
			"05"
		)

		XCTAssertEqual(
			dayFormatter.string(from: date),
			"10"
		)
	}
	
	func testCompactDate() throws {
		let string = String("2020-05-10")
		let dateNumber = string.compactDateNumber
		
		XCTAssertEqual(dateNumber, 200510)
	}

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
