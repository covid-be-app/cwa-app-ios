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

final class BEHTTPClientSubmitCoviCodeTests: XCTestCase {
	let mockUrl = URL(staticString: "http://example.com")
	let expectationsTimeout: TimeInterval = 2

	private var keys: [ENTemporaryExposureKey] {
		let key = ENTemporaryExposureKey.random(Date())

		return [key]
	}
	
	private var datePatientInfectious = BEDateString.fromDateWithoutTime(date: Date())
	private var dateTestCommunicated = BEDateString.fromDateWithoutTime(date: Date())
	private var coviCode = "111111111111"

	func testSubmit_Success() {
		// Arrange
		let stack = MockNetworkStack(
			httpStatus: 200,
			// cannot be nil since this is not a a completion handler can be in (response + nil body)
			responseData: Data()
		)
		let expectation = self.expectation(description: "completion handler is called without an error")

		
		// Act
		HTTPClient.makeWith(mock: stack).submitWithCoviCode(
			keys: keys,
			coviCode: coviCode,
			datePatientInfectious: datePatientInfectious,
			symptomsStartDate: nil,
			dateTestCommunicated: dateTestCommunicated) { error in
			defer { expectation.fulfill() }
			XCTAssertTrue(error == nil)
		}

		waitForExpectations(timeout: expectationsTimeout)
	}

	func testSubmit_Error() {
		// Arrange
		var error: SubmissionError?
		let stack = MockNetworkStack(
			mockSession: MockUrlSession(
				data: nil,
				nextResponse: nil,
				error: TestError.error
			)
		)

		let expectation = self.expectation(description: AppStrings.ExposureSubmission.generalErrorTitle)

		// Act
		HTTPClient.makeWith(mock: stack).submitWithCoviCode(
			keys: keys,
			coviCode: coviCode,
			datePatientInfectious: datePatientInfectious,
			symptomsStartDate: nil,
			dateTestCommunicated: dateTestCommunicated) {
			error = $0
			expectation.fulfill()
		}

		waitForExpectations(timeout: expectationsTimeout)

		// Assert
		XCTAssertNotNil(error)
	}

	func testSubmit_SpecificError() {
		// Arrange
		let stack = MockNetworkStack(
			mockSession: MockUrlSession(
				data: nil,
				nextResponse: nil,
				error: TestError.error
			)
		)
		let expectation = self.expectation(description: "SpecificError")

		// Act
		HTTPClient.makeWith(mock: stack).submitWithCoviCode(
			keys: keys,
			coviCode: coviCode,
			datePatientInfectious: datePatientInfectious,
			symptomsStartDate: nil,
			dateTestCommunicated: dateTestCommunicated) { error in
			defer {
				expectation.fulfill()
			}
			guard let error = error else {
				XCTFail("expected there to be an error")
				return
			}

			if case let SubmissionError.other(otherError) = error {
				XCTAssertNotNil(otherError)
			} else {
				XCTFail("error mismatch")
			}
		}

		waitForExpectations(timeout: expectationsTimeout)
	}

	func testSubmit_ResponseNil() {
		// Arrange
		let mockURLSession = MockUrlSession(data: nil, nextResponse: nil, error: nil)
		let stack = MockNetworkStack(
			mockSession: mockURLSession
		)
		let expectation = self.expectation(description: "ResponseNil")

		// Act
		HTTPClient.makeWith(mock: stack).submitWithCoviCode(
			keys: keys,
			coviCode: coviCode,
			datePatientInfectious: datePatientInfectious,
			symptomsStartDate: nil,
			dateTestCommunicated: dateTestCommunicated) { error in
			defer {
				expectation.fulfill()
			}
			guard let error = error else {
				XCTFail("We expect an error")
				return
			}
			guard case SubmissionError.other = error else {
				XCTFail("We expect error to be of type other")
				return
			}
		}

		waitForExpectations(timeout: expectationsTimeout)
	}

	func testSubmit_Response400() {
		// Arrange
		let stack = MockNetworkStack(
			httpStatus: 400,
			responseData: Data()
		)
		let expectation = self.expectation(description: "Response400")

		// Act
		HTTPClient.makeWith(mock: stack).submitWithCoviCode(
			keys: keys,
			coviCode: coviCode,
			datePatientInfectious: datePatientInfectious,
			symptomsStartDate: nil,
			dateTestCommunicated: dateTestCommunicated) { error in
			defer { expectation.fulfill() }
			guard let error = error else {
				XCTFail("error expected")
				return
			}
			guard case SubmissionError.invalidPayloadOrHeaders = error else {
				XCTFail("We expect error to be of type invalidPayloadOrHeaders")
				return
			}
		}

		waitForExpectations(timeout: expectationsTimeout)
	}

	func testSubmit_Response403() {
		// Arrange
		let stack = MockNetworkStack(
			httpStatus: 403,
			responseData: Data()
		)
		let expectation = self.expectation(description: "Response403")

		// Act
		HTTPClient.makeWith(mock: stack).submitWithCoviCode(
			keys: keys,
			coviCode: coviCode,
			datePatientInfectious: datePatientInfectious,
			symptomsStartDate: nil,
			dateTestCommunicated: dateTestCommunicated) { error in
			defer { expectation.fulfill() }
			guard let error = error else {
				XCTFail("error expected")
				return
			}
			guard case SubmissionError.invalidCoviCode = error else {
				XCTFail("We expect error to be of type invalidTan")
				return
			}
		}

		waitForExpectations(timeout: expectationsTimeout)
	}
}
