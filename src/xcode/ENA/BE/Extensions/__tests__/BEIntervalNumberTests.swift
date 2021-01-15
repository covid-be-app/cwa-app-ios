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
import ExposureNotification

@testable import ENA

class BEIntervalNumberTests: XCTestCase {

	func testFromDateInt() throws {
		let dateInt:BEDateInt = 20200805
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(secondsFromGMT: 0)!
		let date = calendar.date(from: DateComponents(year:2020,month:08,day:05))!
		let intervalNumber = ENIntervalNumber.fromDateInt(dateInt)
		let comparisonValue = (Int(date.timeIntervalSince1970) / 600) * 600
		
		XCTAssertEqual(Int(intervalNumber * 600), comparisonValue)
	}
	
	func testToDate() throws {
		let dateInt:BEDateInt = BEDateInt.today
		let calendar = Calendar.current
		let date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: Date()))
		let intervalNumber = ENIntervalNumber.fromDateInt(dateInt)

		XCTAssertEqual(intervalNumber.date, date)
	}
	
	func testToDateInt() throws {
		let dateInt:BEDateInt = 20200805
		let intervalNumber = ENIntervalNumber.fromDateInt(dateInt)

		XCTAssertEqual(intervalNumber.dateInt, dateInt)
	}
}
