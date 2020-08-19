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

class BEFakeRequestsExecutorTests: XCTestCase {

	var store:Store!
	var exposureManager:ExposureManager!
	var neverRunHTTPRequestObserver: MockUrlSession.URLRequestObserver!
	var neverRunStack: MockNetworkStack!
	
	var urlSequence:[URL] = []
	
    override func setUpWithError() throws {
        store = MockTestStore()
		exposureManager = MockExposureManager(exposureNotificationError: nil, diagnosisKeysResult: nil)
		neverRunHTTPRequestObserver = { request in
			XCTFail("This should never happen")
		}
		neverRunStack = MockNetworkStack(
			httpStatus: 200,
			responseData: nil,
			requestObserver: neverRunHTTPRequestObserver
		)
    }

    func testDisabled() throws {
		let expectation = self.expectation(description: "finished")
		let client = HTTPClient.makeWith(mock: neverRunStack)

		store.isAllowedToPerformBackgroundFakeRequests = false
		
		let executor = BEFakeRequestsExecutor(store:store,exposureManager: exposureManager,client:client)
		
		executor.execute {
			expectation.fulfill()
		}
		
		wait(seconds: 2)
		waitForExpectations(timeout: 2)
	}
	
	func testPendingTestResult() throws {
		let expectation = self.expectation(description: "finished")
		let client = HTTPClient.makeWith(mock: neverRunStack)
		store.isAllowedToPerformBackgroundFakeRequests = true
		store.mobileTestId = BEMobileTestId.random
		store.registrationToken = store.mobileTestId!.registrationToken

		let executor = BEFakeRequestsExecutor(store:store,exposureManager: exposureManager,client:client)
		
		executor.execute {
			expectation.fulfill()
		}
		
		wait(seconds: 2)
		waitForExpectations(timeout: 2)
	}

	func testHasTestResult() throws {
		let expectation = self.expectation(description: "finished")
		let client = HTTPClient.makeWith(mock: neverRunStack)
		store.isAllowedToPerformBackgroundFakeRequests = true
		store.testResult = TestResult.positive

		let executor = BEFakeRequestsExecutor(store:store,exposureManager: exposureManager,client:client)
		
		executor.execute {
			expectation.fulfill()
		}
		
		wait(seconds: 2)
		waitForExpectations(timeout: 2)
	}

	func testDoFirstRequest() throws {
		let expectation = self.expectation(description: "finished")
		let runHTTPRequestObserver:MockUrlSession.URLRequestObserver = { request in
			let configuration = HTTPClient.Configuration.fake
			let url = request.url!
			XCTAssertEqual(url, configuration.testResultURL)
			
			expectation.fulfill()
		}
		let networkStack = MockNetworkStack(
			httpStatus: 200,
			responseData: nil,
			requestObserver: runHTTPRequestObserver
		)
		
		let client = HTTPClient.makeWith(mock: networkStack)
		store.isAllowedToPerformBackgroundFakeRequests = true

		let executor = BEFakeRequestsExecutor(store:store,exposureManager: exposureManager,client:client, isTest:true)
		
		executor.execute {
			
			// make sure the first test query is done
			executor.execute {
				XCTAssertEqual(self.store.isDoingFakeRequests, true)
			}
		}
		
		wait(seconds: 2)
		waitForExpectations(timeout: 2)
	}

	func testMultipleFetchRequests() throws {
		let runHTTPRequestObserver:MockUrlSession.URLRequestObserver = { request in
			let configuration = HTTPClient.Configuration.fake
			let url = request.url!
			XCTAssertEqual(url, configuration.testResultURL)
		}
		let networkStack = MockNetworkStack(
			httpStatus: 200,
			responseData: nil,
			requestObserver: runHTTPRequestObserver
		)
		
		let client = HTTPClient.makeWith(mock: networkStack)
		store.isAllowedToPerformBackgroundFakeRequests = true

		let executor = BEFakeRequestsExecutor(store:store,exposureManager: exposureManager,client:client, isTest:true)
		
		let group = DispatchGroup()
		
		group.enter()
		
		// start test
		executor.execute {
			group.leave()
		}
		
		group.wait()

		let numberOfFakeCalls = store.fakeRequestAmountOfTestResultFetchesToDo

		for _ in 0..<numberOfFakeCalls - 1 {
			group.enter()

			executor.execute {
				group.leave()
			}

			group.wait()
		}
	}

	func testUploadKeys() throws {
		let mockURLSession = makeMockSessionForFakeKeyUpload()

		let networkStack = MockNetworkStack(
			mockSession: mockURLSession
		)
		
		let client = HTTPClient.makeWith(mock: networkStack)
		store.isAllowedToPerformBackgroundFakeRequests = true

		let executor = BEFakeRequestsExecutor(store:store,exposureManager: exposureManager,client:client, isTest:true)
		
		let group = DispatchGroup()
		
		group.enter()
		
		// start test
		executor.execute {
			group.leave()
		}
		
		group.wait()

		let numberOfFakeCalls = store.fakeRequestAmountOfTestResultFetchesToDo

		for _ in 0..<numberOfFakeCalls {
			group.enter()

			executor.execute {
				group.leave()
			}

			group.wait()
		}
	}
	
	private func makeMockSessionForFakeKeyUpload() throws -> BEMockURLSession {
		let configuration = HTTPClient.Configuration.fake
		var datas:[Data?] = []
		var nextResponses:[URLResponse?] = []
		
		// we do a bunch of get test results, only the last should return a result and then we ack it
		// and finally we upload fake keys
		self.urlSequence = Array.init(repeating: configuration.testResultURL, count: self.store.fakeRequestAmountOfTestResultFetchesToDo)
		self.urlSequence.append(configuration.ackTestResultURL)
		self.urlSequence.append(configuration.submissionURL)

		let runHTTPRequestObserver:MockUrlSession.URLRequestObserver = { request in
			let url = request.url!
			
			XCTAssertEqual(self.urlSequence.first!,url)
			self.urlSequence.remove(at: 0)
		}
		

		for _ in 0..<store.fakeRequestAmountOfTestResultFetchesToDo {
			let result = TestResult.pending
			let data = try JSONEncoder().encode(result)
			datas.append(data)
			nextResponses.append(HTTPURLResponse(url: configuration.testResultURL, statusCode: 200, httpVersion: "2", headerFields: nil))
		}
		
		// response for ACK
		datas.append(Data())
		nextResponses.append(HTTPURLResponse(url: configuration.testResultURL, statusCode: 204, httpVersion: "2", headerFields: nil))

		// response for upload
		datas.append(Data())
		nextResponses.append(HTTPURLResponse(url: configuration.testResultURL, statusCode: 200, httpVersion: "2", headerFields: nil))

		return BEMockURLSession(datas: datas, nextResponses: nextResponses, urlRequestObserver: runHTTPRequestObserver)
	}
	
	private func wait(seconds: TimeInterval = 0.2) {
		let expectation = XCTestExpectation(description: "Pause test")
		DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { expectation.fulfill() }
		wait(for: [expectation], timeout: seconds + 1)
	}

}
