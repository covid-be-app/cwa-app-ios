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

class BEURLRequestTests: XCTestCase {

	func testPayloadSize() throws {
		
		var keys:[ENTemporaryExposureKey] = []
		var countries:[BECountry] = []
		let dayCount = 14
		let startDate = Calendar.current.date(byAdding: .day, value: -dayCount, to: Date(), wrappingComponents: true)!
		
		for x in 0..<dayCount+1 {
			let date = Calendar.current.date(byAdding: .day, value: x, to: startDate, wrappingComponents: true)!
			let key = ENTemporaryExposureKey()
			key.transmissionRiskLevel = .min + UInt8(arc4random_uniform(UInt32(ENRiskLevel.max - ENRiskLevel.min)))
			key.rollingPeriod = 144
			key.rollingStartNumber = ENIntervalNumber.fromDateInt(BEDateInt.fromDate(date))
			key.keyData = Data(count: 16)
			let country = BECountry(code3: "BEL", name: ["nl":"België","fr":"Belgique","en":"Belgium","de":"Belgien"])

			keys.append(key)
			countries.append(country)
		}

		
		let emptyRequest = try URLRequest.submitKeysRequest(
			configuration: HTTPClient.Configuration.fake,
			mobileTestId: BEMobileTestId.random,
			testResult: TestResult.positive,
			keys: [],
			countries: [])

		let emptyBody = emptyRequest.httpBody!

		for x in 1..<dayCount {
			let keyRequest = try URLRequest.submitKeysRequest(
				configuration: HTTPClient.Configuration.fake,
				mobileTestId: BEMobileTestId.random,
				testResult: TestResult.positive,
				keys: Array(keys.prefix(upTo: x)),
				countries: Array(countries.prefix(upTo: x))
			)
			
			let keyBody = keyRequest.httpBody!
			
			XCTAssertEqual(emptyBody.count, keyBody.count)
		}
	}
}

/*
//
// Corona-Warn-App
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
import ExposureNotification
import XCTest

final class BEHTTPClientPaddingTests: XCTestCase {
	let mockUrl = URL(staticString: "http://example.com")
	let expectationsTimeout: TimeInterval = 2

	private var mobileTestId = BEMobileTestId.random
	private var dateTestCommunicated = "2020-07-25"
	
	func testPayloadSize() throws {
		var keys:[ENTemporaryExposureKey] = []
		var countries:[BECountry] = []
		let dayCount = 14
		let startDate = Calendar.current.date(byAdding: .day, value: -dayCount, to: Date(), wrappingComponents: true)!
		
		for x in 0..<dayCount+1 {
			let date = Calendar.current.date(byAdding: .day, value: x, to: startDate, wrappingComponents: true)!
			let key = ENTemporaryExposureKey()
			key.transmissionRiskLevel = .min + UInt8(arc4random_uniform(UInt32(ENRiskLevel.max - ENRiskLevel.min)))
			key.rollingPeriod = 144
			key.rollingStartNumber = ENIntervalNumber.fromDateInt(BEDateInt.fromDate(date))
			let country = BECountry(code3: "BEL", name: ["nl":"België","fr":"Belgique","en":"Belgium","de":"Belgien"])

			keys.append(key)
			countries.append(country)
		}

		let configuration = HTTPClient.Configuration.fake
		let testResultToUse = TestResult.positive

		let request1 = try URLRequest.submitKeysRequest(
			configuration: configuration,
			mobileTestId: mobileTestId,
			testResult: testResultToUse,
			keys: keys,
			countries: countries
		)

		let request2 = try URLRequest.submitKeysRequest(
			configuration: configuration,
			mobileTestId: mobileTestId,
			testResult: testResultToUse,
			keys: Array(keys.prefix(upTo: 5)),
			countries: Array(countries.prefix(upTo: 5))
		)
		
		XCTAssertEqual(request1.httpBody!.count,request2.httpBody!.count)
	}
}

*/
