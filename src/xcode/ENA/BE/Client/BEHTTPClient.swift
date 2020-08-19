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

import Foundation
import ExposureNotification

class BEHTTPClient : HTTPClient {
	
	// no longer supported
	override func submit(keys: [ENTemporaryExposureKey], tan: String, completion: @escaping HTTPClient.SubmitKeysCompletionHandler) {
		fatalError("Deprecated")
	}
	
	override func getTestResult(forDevice registrationToken: String, completion completeWith: @escaping TestResultHandler) {
		let url = configuration.testResultURL
		let bodyValues = ["testResultPollingToken": registrationToken]

		do {
			let encoder = JSONEncoder()

			let data = try encoder.encode(bodyValues)

			session.POST(url, data) { result in
				switch result {
				case let .success(response):
					guard response.hasAcceptableStatusCode else {
						completeWith(.failure(.serverError(response.statusCode)))
						return
					}
					guard let testResultResponseData = response.body else {
						completeWith(.failure(.invalidResponse))
						logError(message: "Failed to register Device with invalid response")
						return
					}
					do {
						let decoder = JSONDecoder()
						let testResult = try decoder.decode(
							TestResult.self,
							from: testResultResponseData
						)
						
						if testResult.result != .pending {
							self.ackTestDownload(forDevice: registrationToken) {
								log(message:"Ack finished")
							}
						}
						
						completeWith(.success(testResult))
					} catch {
						logError(message: "Failed to get test result with invalid response payload structure")
						completeWith(.failure(.invalidResponse))
					}
				case let .failure(error):
					completeWith(.failure(error))
					logError(message: "Failed to get test result due to error: \(error).")
				}
			}
		} catch {
			completeWith(.failure(.invalidResponse))
			return
		}
	}
	
	func ackTestDownload(forDevice registrationToken: String, completionBlock: @escaping(() -> Void)) {
		let ackUrl = self.configuration.ackTestResultURL
		let bodyValues = ["testResultPollingToken": registrationToken]
		let encoder = JSONEncoder()

		// we don't need this to run succesfully.
		// failure would mean that the test result is not deleted immediately from the server
		// but it will be cleaned up in the auto-delete of old test results ran server-side anyway after a couple of days.
		// Normally this will happen very rarely, since we just managed to do a succesful test download request
		// so the connection should still work in 99.9% of the cases
		
		if let data = try? encoder.encode(bodyValues) {
			self.session.POST(ackUrl, data) { result in
				switch result {
				case .success:
					log(message:"Ack succeeded")
				case let .failure(error):
					logError(message: "Ack failed due to error: \(error).")
				}
				
				completionBlock()
			}
		} else {
			completionBlock()
		}
	}

	
	func submit(
		keys: [ENTemporaryExposureKey],
		countries: [BECountry],
		mobileTestId: BEMobileTestId? = nil,
		testResult:TestResult? = nil,
		isFake:Bool = false,
		completion: @escaping SubmitKeysCompletionHandler
	) {
		if !isFake {
			guard
				let _ = testResult,
				let _ = mobileTestId else {
					fatalError("Real requests require real test result and mobile test id")
			}
		}
		
		let mobileTestIdToUse = mobileTestId ?? BEMobileTestId.random
		let testResultToUse = testResult ?? TestResult.positive
		
		guard let request = try? URLRequest.submitKeysRequest(
			configuration: configuration,
			mobileTestId: mobileTestIdToUse,
			testResult: testResultToUse,
			keys: keys,
			countries: countries
		) else {
			completion(.requestCouldNotBeBuilt)
			return
		}

		session.response(for: request) { result in
			switch result {
			case let .success(response):
				switch response.statusCode {
				case 200: completion(nil)
				case 201: completion(nil)
				case 400: completion(.invalidPayloadOrHeaders)
				case 403: completion(.invalidTan)
				default: completion(.serverError(response.statusCode))
				}
			case let .failure(error):
				completion(.other(error))
			}
		}
	}
}
