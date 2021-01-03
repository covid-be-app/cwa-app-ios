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

class BEExposureSubmissionServiceTests: XCTestCase {
	var keys:[ENTemporaryExposureKey] = []
	var dateFormatter:DateFormatter!
	var urlSequence:[URL] = []
	var expectation:XCTestExpectation!
	
    override func setUpWithError() throws {
		// generate fake keys for the last 2 weeks
		let dayCount = 14
		let startDate = Calendar.current.date(byAdding: .day, value: -dayCount, to: Date(), wrappingComponents: true)!
		
		for x in 0..<dayCount+1 {
			let date = Calendar.current.date(byAdding: .day, value: x, to: startDate, wrappingComponents: true)!
			let key = ENTemporaryExposureKey.random(date)
			
			keys.append(key)
		}

		dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd"
	}

	// We want to test that the correct range of keys is returned.
	// if we don't apply any filtering all keys will be returned, but we are only interested in the keys in the range [t0 .. t3]
	// whereby t0 is the date the user is infectious
	// and t3 is the date on which the test result was communicated to the user
    func testGetKeys() throws {
		dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd"

		let finishedExpectation = self.expectation(description: "finished getting keys")
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let client = ClientMock()
		let store = MockTestStore()
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)

		// receive result today
		let dateTestCommunicated = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
		
		// infectious 8 days ago
		let datePatientInfectious = Calendar.current.date(byAdding: .day, value: -8, to: dateTestCommunicated)!
		
		// onset of symptoms 6 days ago
		let symptomsStartDate = Calendar.current.date(byAdding: .day, value: -6, to: dateTestCommunicated)!

		// did test 4 days ago
		let dateTestCollected = Calendar.current.date(byAdding: .day, value: -4, to: dateTestCommunicated)!
		
		let testCollectedDateString = dateFormatter.string(from:dateTestCollected)
		let testCommunicatedDateString = dateFormatter.string(from:dateTestCommunicated)
		
		store.mobileTestId = BEMobileTestId(symptomsStartDate: symptomsStartDate)
		store.testResult = TestResult(result: .positive, channel: .lab, dateCollected: testCollectedDateString, dateTestCommunicated: testCommunicatedDateString)

		service.retrieveDiagnosisKeys{ result in
			switch result {
			case .failure:
				XCTAssert(false)
			case .success(let keys):
				keys.forEach{ key in
					XCTAssert(datePatientInfectious <= key.rollingStartNumber.date,"Key \(key.rollingStartNumber.date) earlier than infectious date \(datePatientInfectious)")
					XCTAssert(dateTestCommunicated >= key.rollingStartNumber.date,"Key later than test communicated date")
				}
				finishedExpectation.fulfill()
			}
		}
		
		waitForExpectations(timeout: 10)
    }
	
	func testOutdatedTestRequestDeletion() throws {
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let client = ClientMock()
		let store = try SecureStore(at: URL(staticString: ":memory:"), key: "123456")
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		let mobileTestId = BEMobileTestId()
		store.mobileTestId = mobileTestId
		sleep(4)
		store.deleteMobileTestIdAfterTimeInterval = 2
		XCTAssertEqual(service.deleteMobileTestIdIfOutdated(),true)
		XCTAssert(store.mobileTestId == nil)

		store.mobileTestId = mobileTestId
		sleep(2)
		store.deleteMobileTestIdAfterTimeInterval = 20
		XCTAssertEqual(service.deleteMobileTestIdIfOutdated(),false)
		XCTAssert(store.mobileTestId != nil)
	}
	
	func testUploadKeysAfterNegativeTest() throws {
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let store = try SecureStore(at: URL(staticString: ":memory:"), key: "123456")
		let mockURLSession = try makeMockSessionForFakeKeyUpload(testResult:TestResult.negative)

		let networkStack = MockNetworkStack(
			mockSession: mockURLSession
		)
		
		let client = HTTPClient.makeWith(mock: networkStack)
		store.isAllowedToPerformBackgroundFakeRequests = true
		
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		service.generateMobileTestId(nil)
		service.getTestResult{ result in
			switch result {
			case .failure:
				XCTAssert(false)
			case.success(let testResult):
				XCTAssertEqual(testResult.result, TestResult.Result.negative)
			}
		}
		
		waitForExpectations(timeout: 20)
	}
	
	func testDoNotUploadKeysAfterPositiveTest() throws {
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let store = try SecureStore(at: URL(staticString: ":memory:"), key: "123456")
		let mockURLSession = try makeMockSessionForFakeKeyUpload(testResult:TestResult.positive)

		let networkStack = MockNetworkStack(
			mockSession: mockURLSession
		)
		
		let client = HTTPClient.makeWith(mock: networkStack)
		store.isAllowedToPerformBackgroundFakeRequests = true
		
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		service.generateMobileTestId(nil)
		service.getTestResult{ result in
			switch result {
			case .failure:
				XCTAssert(false)
			case.success(let testResult):
				XCTAssertEqual(testResult.result, TestResult.Result.positive)
			}
		}
		
		waitForExpectations(timeout: 20)
	}
	
	func testTestDeletion() throws {
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let client = ClientMock()
		let store = MockTestStore()
		
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		service.generateMobileTestId(nil)
		store.testResult = TestResult.negative
		store.testResultReceivedTimeStamp = Int64(Date().timeIntervalSince1970)

		service.deleteTestResultIfOutdated()
		XCTAssertNotNil(store.testResult)
		
		store.deleteTestResultAfterTimeInterval = 10000000
		store.deleteTestResultAfterDate = Date().addingTimeInterval(1)
		sleep(2)

		service.deleteTestResultIfOutdated()
		XCTAssertNil(store.testResult)
		XCTAssertNil(store.mobileTestId)
		XCTAssertNil(store.mobileTestId)
		XCTAssertNil(store.deleteTestResultAfterDate)
	}

	func testTestDeletion2() throws {
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let client = ClientMock()
		let store = MockTestStore()
		
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		service.generateMobileTestId(nil)
		store.testResult = TestResult.negative
		store.testResultReceivedTimeStamp = Int64(Date().timeIntervalSince1970)

		service.deleteTestResultIfOutdated()
		XCTAssertNotNil(store.testResult)
		
		store.deleteTestResultAfterTimeInterval = 1
		sleep(2)

		service.deleteTestResultIfOutdated()
		XCTAssertNil(store.testResult)
		XCTAssertNil(store.mobileTestId)
		XCTAssertNil(store.mobileTestId)
		XCTAssertNil(store.deleteTestResultAfterDate)
	}

	func testTestDeletion3() throws {
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let client = ClientMock()
		let store = MockTestStore()
		
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)
		service.generateMobileTestId(nil)
		store.testResult = TestResult.negative
		store.testResultReceivedTimeStamp = Int64(Date().timeIntervalSince1970)

		service.deleteTestResultIfOutdated()
		XCTAssertNotNil(store.testResult)
		
		store.deleteTestResultAfterTimeInterval = 100
		sleep(2)

		service.deleteTestResultIfOutdated()
		XCTAssertNotNil(store.testResult)
	}
	
	private func makeMockSessionForFakeKeyUpload(testResult: TestResult) throws -> BEMockURLSession {
		let configuration = HTTPClient.Configuration.fake
		var datas:[Data?] = []
		var nextResponses:[URLResponse?] = []

		expectation = self.expectation(description: "Fake upload done")

		urlSequence.append(configuration.testResultURL)
		urlSequence.append(configuration.ackTestResultURL)
		
		if testResult.result == .negative {
			urlSequence.append(configuration.submissionURL)
		}

		let runHTTPRequestObserver:MockUrlSession.URLRequestObserver = { request in
			let url = request.url!

			XCTAssertEqual(self.urlSequence.first!,url)
			self.urlSequence.remove(at: 0)
			if self.urlSequence.isEmpty {
				self.expectation.fulfill()
			}
		}
		

		let data = try JSONEncoder().encode(testResult)
		datas.append(data)
		nextResponses.append(HTTPURLResponse(url: configuration.testResultURL, statusCode: 200, httpVersion: "2", headerFields: nil))

		// response for ACK
		datas.append(Data())
		nextResponses.append(HTTPURLResponse(url: configuration.testResultURL, statusCode: 204, httpVersion: "2", headerFields: nil))

		// response for upload
		if testResult.result == .negative {
			datas.append(Data())
			nextResponses.append(HTTPURLResponse(url: configuration.testResultURL, statusCode: 200, httpVersion: "2", headerFields: nil))
		}

		return BEMockURLSession(datas: datas, nextResponses: nextResponses, urlRequestObserver: runHTTPRequestObserver)
	}
}
