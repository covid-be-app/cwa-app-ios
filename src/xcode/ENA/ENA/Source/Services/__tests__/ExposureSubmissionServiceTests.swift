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

class ExposureSubmissionServiceTests: XCTestCase {
	let expectationsTimeout: TimeInterval = 2
	let keys = [ENTemporaryExposureKey.random(Date())]

	// MARK: - Exposure Submission Tests

	func testSubmitExpousure_Success() {
		// Arrange
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let client = ClientMock()
		let store = MockTestStore()
		store.mobileTestId = BEMobileTestId.random
		store.testResult = TestResult.positiveWithDate(store.mobileTestId!.creationDate)
	
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		let expectation = self.expectation(description: "Success")
		var error: ExposureSubmissionError?

		service.retrieveDiagnosisKeys { result in
			// Act
			switch result {
			case .success(let keys):
				service.submitExposure(keys: keys) {
					error = $0
					expectation.fulfill()
				}
			case .failure(let keyError):
				error = keyError
			}
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

		service.retrieveDiagnosisKeys { result in
			// Act
			switch result {
			case .success:
				XCTFail("error expected")
			case .failure(let error):
				guard case ExposureSubmissionError.noKeys = error else {
					XCTFail("We expect error to be of type expectationsTimeout")
					return
				}
				expectation.fulfill()
			}
		}

		waitForExpectations(timeout: expectationsTimeout)
	}

	func testSubmitExpousure_EmptyKeys() {
		// Arrange
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (nil, nil))
		let client = ClientMock()
		let store = MockTestStore()
		store.mobileTestId = BEMobileTestId.random
		store.testResult = TestResult.positiveWithDate(store.mobileTestId!.creationDate)

		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		let expectation = self.expectation(description: "EmptyKeys")

		service.retrieveDiagnosisKeys { result in
			defer { expectation.fulfill() }
			switch result {
			case .success:
				XCTFail("error expected")
			case .failure(let error):
				guard case ExposureSubmissionError.noKeys = error else {
					XCTFail("We expect error to be of type noKeys")
					return
				}
			}
		}

		waitForExpectations(timeout: expectationsTimeout)
	}

	func testSubmitExpousure_NoTestResult() {
		// Arrange

		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let client = ClientMock()
		let store = MockTestStore()
		store.mobileTestId = BEMobileTestId.random

		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		let expectation = self.expectation(description: "NoTestResult")

		service.retrieveDiagnosisKeys { result in
			switch result {
			case .success:
				XCTFail("error expected")
			case .failure(let error):
				XCTAssert(error == .internal)
				expectation.fulfill()
			}
		}

		waitForExpectations(timeout: expectationsTimeout)
	}
}
