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
		let dayCount = 14
		let startDate = Calendar.current.date(byAdding: .day, value: -dayCount, to: Date())!

		for x in 0..<dayCount+1 {
			let date = Calendar.current.date(byAdding: .day, value: x, to: startDate)!
			let key = ENTemporaryExposureKey.random(date)

			keys.append(key)
		}

		
		let emptyRequest = try URLRequest.submitKeysRequest(
			configuration: HTTPClient.Configuration.fake,
			mobileTestId: BEMobileTestId.random,
			testResult: TestResult.positive,
			keys: [])

		let emptyBody = emptyRequest.httpBody!

		for x in 1..<dayCount {
			let keyRequest = try URLRequest.submitKeysRequest(
				configuration: HTTPClient.Configuration.fake,
				mobileTestId: BEMobileTestId.random,
				testResult: TestResult.positive,
				keys: Array(keys.prefix(upTo: x))
			)
			
			let keyBody = keyRequest.httpBody!
			
			XCTAssertEqual(emptyBody.count, keyBody.count)
		}
	}
	
	func testHeaders() throws {
		var keys:[ENTemporaryExposureKey] = []
		let dayCount = 14
		let startDate = Calendar.current.date(byAdding: .day, value: -dayCount, to: Date(), wrappingComponents: true)!
		let headerKeys = ["Secret-Key","Random-String","Date-Patient-Infectious","Date-Test-Communicated","Result-Channel","Content-Type","Covi-Code"]
		let onsetOfSymptomsKey = "Date-Onset-Of-Symptoms"

		for x in 0..<dayCount+1 {
			let date = Calendar.current.date(byAdding: .day, value: x, to: startDate, wrappingComponents: true)!
			let key = ENTemporaryExposureKey.random(date)

			keys.append(key)
		}

		let keyRequest = try URLRequest.submitKeysRequest(
			configuration: HTTPClient.Configuration.fake,
			mobileTestId: BEMobileTestId(),
			testResult: TestResult.positive,
			keys: keys
		)
		
		var headerFields = keyRequest.allHTTPHeaderFields!
		var allHeaderKeys = headerKeys
		
		headerFields.keys.forEach{ key in
			XCTAssertNotEqual(key, onsetOfSymptomsKey)
			
			guard let index = allHeaderKeys.firstIndex(of: key) else {
				XCTAssert(false)
				return
			}
			
			allHeaderKeys.remove(at: index)
		}
		
		XCTAssertEqual(allHeaderKeys.count, 0)

		let keyRequest2 = try URLRequest.submitKeysRequest(
			configuration: HTTPClient.Configuration.fake,
			mobileTestId: BEMobileTestId(symptomsStartDate: Date()),
			testResult: TestResult.positive,
			keys: keys
		)
		
		headerFields = keyRequest2.allHTTPHeaderFields!
		allHeaderKeys = headerKeys
		allHeaderKeys.append(onsetOfSymptomsKey)
		
		headerFields.keys.forEach{ key in
			guard let index = allHeaderKeys.firstIndex(of: key) else {
				XCTAssert(false)
				return
			}
			
			allHeaderKeys.remove(at: index)
		}
		
		XCTAssertEqual(allHeaderKeys.count, 0)
	}
	
	func testEqualSize() throws {
		var keys:[ENTemporaryExposureKey] = []
		let dayCount = 7
		let startDate = Calendar.current.date(byAdding: .day, value: -dayCount, to: Date(), wrappingComponents: true)!
		let mobileTestId = BEMobileTestId()
		
		for x in 0..<dayCount+1 {
			let date = Calendar.current.date(byAdding: .day, value: x, to: startDate, wrappingComponents: true)!
			let key = ENTemporaryExposureKey.random(date)

			keys.append(key)
		}

		let keyRequest = try URLRequest.submitKeysRequest(
			configuration: HTTPClient.Configuration.fake,
			mobileTestId: BEMobileTestId(),
			testResult: TestResult.positive,
			keys: keys
		)
		
		let coviCodeKeyRequest = try URLRequest.submitCoviCodeKeysRequest(
			configuration: HTTPClient.Configuration.fake,
			coviCode: "111111111111",
			datePatientInfectious: mobileTestId.datePatientInfectious,
			symptomsStartDate: mobileTestId.symptomsStartDate,
			dateTestCommunicated: TestResult.positive.dateTestCommunicated,
			keys: keys)
		
		guard
			var firstHeaders = keyRequest.allHTTPHeaderFields,
			var secondHeaders = coviCodeKeyRequest.allHTTPHeaderFields,
			let firstBody = keyRequest.httpBody,
			let secondBody = coviCodeKeyRequest.httpBody
			else {
			XCTAssert(false)
			return
		}

		// we know the base64 secret key can have different lengths, so we remove it
		firstHeaders.removeValue(forKey: "Secret-Key")
		secondHeaders.removeValue(forKey: "Secret-Key")

		let firstData = try JSONEncoder().encode(firstHeaders)
		let secondData = try JSONEncoder().encode(secondHeaders)
		
		XCTAssertEqual(firstData.count, secondData.count)
		XCTAssertEqual(firstBody.count, secondBody.count)
	}
}
