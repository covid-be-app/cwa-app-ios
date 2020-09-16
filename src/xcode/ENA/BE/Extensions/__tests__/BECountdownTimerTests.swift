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

class BECountdownTimerTests: XCTestCase {

	func testCeil() throws {
		let now = Date()
		let targetDate = now.addingTimeInterval(60)
		let timer = CountdownTimer(countdownTo: targetDate)
		
		XCTAssertEqual(timer.hourCeil,1)
	}

	func testCeil2() throws {
		let now = Date()
		let targetDate = now
		let timer = CountdownTimer(countdownTo: targetDate)
		
		XCTAssertEqual(timer.hourCeil,0)
	}

	func testCeil3() throws {
		let now = Date()
		let targetDate = now.addingTimeInterval(62)
		let timer = CountdownTimer(countdownTo: targetDate)
		
		XCTAssertEqual(timer.hourCeil,1)
	}

	func testCeil4() throws {
		let now = Date()
		let targetDate = now.addingTimeInterval(3600)
		let timer = CountdownTimer(countdownTo: targetDate)
		
		XCTAssertEqual(timer.hourCeil,1)
	}

	func testCeil5() throws {
		let now = Date()
		let targetDate = now.addingTimeInterval(3605)
		let timer = CountdownTimer(countdownTo: targetDate)
		
		XCTAssertEqual(timer.hourCeil,2)
	}

}
