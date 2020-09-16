//
// Corona-Warn-App
//
// Modified by Devside SRL
//
// SAP SE and all other contributors
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

@testable import ENA
import Foundation
import XCTest

final class RiskTests: XCTestCase {
	func testGetNumberOfDaysActiveTracing_LessThanOneDay() {
		let details = mockDetails(activeTracing: .init(interval: .init(hours: 11)))
		XCTAssertEqual(details.numberOfDaysWithActiveTracing, 0)
	}

	func testGetNumberOfDaysActiveTracing_ZeroHours() {
		let details = mockDetails(activeTracing: .init(interval: .init(hours: 0)))
		XCTAssertEqual(details.numberOfDaysWithActiveTracing, 0)
	}

	func testGetNumberOfDaysActiveTracing_OneDayRoundedDown() {
		let details = mockDetails(activeTracing: .init(interval: .init(hours: 25)))
		XCTAssertEqual(details.numberOfDaysWithActiveTracing, 1)
	}

	func testGetNumberOfDaysActiveTracing_OneDayExact() {
		let details = mockDetails(activeTracing: .init(interval: .init(hours: 25)))
		XCTAssertEqual(details.numberOfDaysWithActiveTracing, 1)
	}

	func testGetNumberOfDaysActiveTracing_FourteenDaysExact() {
		let details = mockDetails(activeTracing: .init(interval: .init(hours: 14 * 24)))
		XCTAssertEqual(details.numberOfDaysWithActiveTracing, 14)
	}
	
	func testDaysSinceLastExposure() {
		let risk = Risk(
			level: .increased,
			details: Risk.Details(
				daysSinceLastExposure: 0,
				numberOfExposures: 1,
				activeTracing: .init(interval: 336 * 3600),
				exposureDetectionDate: Date().addingTimeInterval( -48 * 60 * 60 )
			),
			riskLevelHasChanged: true
		)

		XCTAssertEqual(risk.details.daysSinceLastExposure, 0)
		XCTAssertEqual(risk.details.calendarDaysSinceLastExposure, 2)
	}
}

extension RiskTests {
	func mockDetails(activeTracing: ActiveTracing) -> Risk.Details {
		Risk.Details(
			numberOfExposures: 0,
			activeTracing: activeTracing,
			exposureDetectionDate: Date()
		)
	}
}
