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


class BEExposureSubmissionService : ENAExposureSubmissionService {
	typealias BEExposureSubmissionGetKeysHandler = (Result<[ENTemporaryExposureKey], ExposureSubmissionError>) -> Void
	
	var httpClient:BEHTTPClient {
		get {
			return client as! BEHTTPClient
		}
	}
	
	var mobileTestId:BEMobileTestId? {
		get {
			return store.mobileTestId
		}
		set {
			store.mobileTestId = newValue

			if newValue != nil {
				print(newValue!)
				store.registrationToken = newValue!.registrationToken
			}
		}
	}
	
	override func deleteTest() {
		super.deleteTest()
		store.mobileTestId = nil
		store.testResult = nil
	}
	
	// no longer supported
	override func getRegistrationToken(
		forKey deviceRegistrationKey: DeviceRegistrationKey,
		completion completeWith: @escaping RegistrationHandler
	) {
		fatalError()
	}
	
	override func getTestResult(_ completeWith: @escaping TestResultHandler) {
		guard let registrationToken = store.registrationToken else {
			completeWith(.failure(.noRegistrationToken))
			return
		}

		client.getTestResult(forDevice: registrationToken) { result in
			switch result {
			case let .failure(error):
				completeWith(.failure(self.parseError(error)))
			case let .success(testResult):
				if testResult.result != .pending {
					self.store.testResultReceivedTimeStamp = Int64(Date().timeIntervalSince1970)
					self.store.testResult = testResult
				}
				completeWith(.success(testResult))
			}
		}
	}
	
	func retrieveDiagnosisKeys(completionHandler: @escaping BEExposureSubmissionGetKeysHandler) {
		diagnosiskeyRetrieval.accessDiagnosisKeys { keys, error in
			if let error = error {
				logError(message: "Error while retrieving diagnosis keys: \(error.localizedDescription)")
				completionHandler(.failure(self.parseError(error)))
				return
			}

			guard var keys = keys, !keys.isEmpty else {
				completionHandler(.failure(.noKeys))
				return
			}
			keys.processedForSubmission()

			completionHandler(.success(keys))
		}

	}

	
	/// This method submits the exposure keys. Additionally, after successful completion,
	/// the timestamp of the key submission is updated.
	func submitExposure(keys:[ENTemporaryExposureKey],countries:[BECountry], completionHandler: @escaping ExposureSubmissionHandler) {
		log(message: "Started exposure submission...")
		self.submit(
			keys:keys,
			countries:countries,
			completion: completionHandler)
	}

	// no longer used
	override func submitExposure( completionHandler: @escaping ExposureSubmissionHandler) {
		fatalError()
	}

	private func submit(keys: [ENTemporaryExposureKey], countries:[BECountry], completion: @escaping ExposureSubmissionHandler) {
		
		guard
			let testResult = store.testResult,
			let mobileTestId = store.mobileTestId
		else {
			completion(.other("no_test_result_or_test_id"))
			return
		}
		
		httpClient.submit(keys: keys, countries:countries, mobileTestId: mobileTestId, dateTestCommunicated: testResult.dateTestCommunicated) { error in
			if let error = error {
				logError(message: "Error while submiting diagnosis keys: \(error.localizedDescription)")
				completion(self.parseError(error))
				return
			}

			self.submitExposureCleanup()
			log(message: "Successfully completed exposure sumbission.")
			completion(nil)
		}
	}
}
