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

@testable import ENA
import ExposureNotification
import XCTest

class ExposureSubmissionServiceCoviCodeTests: XCTestCase {
	let expectationsTimeout: TimeInterval = 2
	let keys = [ENTemporaryExposureKey.random(Date())]

	// MARK: - Exposure Submission Tests

	private let coviCode = "111111111111"
	
	func testSubmitExpousure_Success() {
		// Arrange
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let client = ClientMock()
		let store = MockTestStore()
	
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		let expectation = self.expectation(description: "Success")
		var error: ExposureSubmissionError?
		
		service.submitExposureWithCoviCode(coviCode: coviCode, symptomsStartDate: nil) {
			error = $0
			expectation.fulfill()
		}

		waitForExpectations(timeout: expectationsTimeout)

		// Assert
		XCTAssertNil(error)
	}

	func testSubmitExpousure_NoKeys() {
		// Arrange
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (nil, nil))
		let client = ClientMock()
		let store = MockTestStore()
		store.mobileTestId = BEMobileTestId.random
		store.testResult = TestResult.positiveWithDate(store.mobileTestId!.creationDate)

		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		let expectation = self.expectation(description: "NoKeys")

		service.submitExposureWithCoviCode(coviCode: coviCode, symptomsStartDate: nil) { error in
			guard let error = error else {
				XCTFail("error expected")
				return
			}

			guard case ExposureSubmissionError.noKeys = error else {
				XCTFail("We expect error to be of type expectationsTimeout")
				return
			}
			expectation.fulfill()
		}

		waitForExpectations(timeout: expectationsTimeout)
	}

	func testSubmitExpousure_EmptyKeys() {
		// Arrange
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (nil, nil))
		let client = ClientMock()
		let store = MockTestStore()

		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		let expectation = self.expectation(description: "EmptyKeys")

		service.submitExposureWithCoviCode(coviCode: coviCode, symptomsStartDate: nil) { error in
			guard let error = error else {
				XCTFail("error expected")
				return
			}

			guard case ExposureSubmissionError.noKeys = error else {
				XCTFail("We expect error to be of type noKeys")
				return
			}

			expectation.fulfill()
		}

		waitForExpectations(timeout: expectationsTimeout)
	}

	func testSubmitExpousure_InvalidCoviCode() {
		// Arrange
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let client = ClientMock(submissionError:.invalidCoviCode)
		let store = MockTestStore()
	
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		let expectation = self.expectation(description: "Success")
		
		service.submitExposureWithCoviCode(coviCode: coviCode, symptomsStartDate: nil) { error in

			guard let error = error else {
				XCTFail("error expected")
				return
			}

			guard case ExposureSubmissionError.invalidCoviCode = error else {
				XCTFail("We expect error to be of type noKeys")
				return
			}

			expectation.fulfill()
		}

		waitForExpectations(timeout: expectationsTimeout)
	}
}
