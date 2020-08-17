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

		// :BE: update key name for body
		let bodyValues = ["testResultPollingToken": registrationToken]
		do {
			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted

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
							let ackUrl = self.configuration.ackTestResultURL
							
							// we don't wait for this to return as even if it fails it's not an issue
							// failure would mean that the test result is not deleted immediately from the server
							// but it will be cleaned up in the auto-delete of old test results ran server-side anyway after a couple of days.
							// Normally this will happen very rarely, since we just managed to do a succesful test download request
							// so the connection should still work in 99.9% of the cases
							
							self.session.POST(ackUrl, data) { result in
								switch result {
								case .success:
									log(message:"Ack succeeded")
								case let .failure(error):
									logError(message: "Ack failed due to error: \(error).")
								}
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

	
	func submit(
		keys: [ENTemporaryExposureKey],
		countries: [BECountry],
		mobileTestId: BEMobileTestId,
		testResult:TestResult,
		completion: @escaping SubmitKeysCompletionHandler
	) {
		guard let request = try? URLRequest.submitKeysRequest(
			configuration: configuration,
			mobileTestId: mobileTestId,
			testResult: testResult,
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

private extension URLRequest {
	static func submitKeysRequest(
		configuration: HTTPClient.Configuration,
		mobileTestId: BEMobileTestId,
		testResult:TestResult,
		keys: [ENTemporaryExposureKey],
		countries: [BECountry]
	) throws -> URLRequest {
		let payload = SAP_SubmissionPayload.with {
			$0.keys = keys.map { $0.sapKey }
			$0.countries = countries.map { $0.code3 }
		}
		let payloadData = try payload.serializedData()
		let url = configuration.submissionURL
		/*
		let fileManager = FileManager.default
		let directoryURL = try! fileManager
			.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
			.appendingPathComponent("keys.dat")

		try! payloadData.write(to:directoryURL)
*/
		var request = URLRequest(url: url)

		request.setValue(
			mobileTestId.secretKeyBase64String,
			forHTTPHeaderField: "Secret-Key"
		)

		request.setValue(
			mobileTestId.randomString,
			forHTTPHeaderField: "Random-String"
		)

		request.setValue(
			mobileTestId.datePatientInfectious,
			forHTTPHeaderField: "Date-Patient-Infectious"
		)

		request.setValue(
			testResult.dateTestCommunicated,
			forHTTPHeaderField: "Date-Test-Communicated"
		)

		request.setValue(
			"\(testResult.resultChannel.rawValue)",
			forHTTPHeaderField: "Result-Channel"
		)

		request.setValue(
			"0",
			// Requests with a value of "0" will be fully processed.
			// Any other value indicates that this request shall be
			// handled as a fake request." ,
			forHTTPHeaderField: "cwa-fake"
		)

		request.setValue(
			"application/x-protobuf",
			forHTTPHeaderField: "Content-Type"
		)

		request.httpMethod = "POST"
		request.httpBody = payloadData

		return request
	}
}

