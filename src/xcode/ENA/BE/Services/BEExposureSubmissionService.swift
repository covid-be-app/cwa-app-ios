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

	var secureStore:SecureStore {
		get {
			return store as! SecureStore
		}
	}
	
	var httpClient:BEHTTPClient {
		get {
			return client as! BEHTTPClient
		}
	}
	
	var mobileTestId:BEMobileTestId? {
		get {
			return secureStore.mobileTestId
		}
		set {
			secureStore.mobileTestId = newValue

			if newValue != nil {
				print(newValue!)
				secureStore.registrationToken = newValue!.registrationToken
			}
		}
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
					self.secureStore.testResultReceivedTimeStamp = Int64(Date().timeIntervalSince1970)
					self.secureStore.testResult = testResult
				}
				completeWith(.success(testResult))
			}
		}
	}

	
	/// This method submits the exposure keys. Additionally, after successful completion,
	/// the timestamp of the key submission is updated.
	override func submitExposure(completionHandler: @escaping ExposureSubmissionHandler) {
		log(message: "Started exposure submission...")

		diagnosiskeyRetrieval.accessDiagnosisKeys { keys, error in
			if let error = error {
				logError(message: "Error while retrieving diagnosis keys: \(error.localizedDescription)")
				completionHandler(self.parseError(error))
				return
			}

			guard var keys = keys, !keys.isEmpty else {
				completionHandler(.noKeys)
				// We perform a cleanup in order to set the correct
				// timestamps, despite not having communicated with the backend,
				// in order to show the correct screens.
				self.submitExposureCleanup()
				return
			}
			keys.processedForSubmission()

			self.submit(keys, completion: completionHandler)
		}
	}

	private func submit(_ keys: [ENTemporaryExposureKey], completion: @escaping ExposureSubmissionHandler) {
		
		guard
			let testResult = secureStore.testResult,
			let mobileTestId = secureStore.mobileTestId
		else {
			completion(.other("no_test_result_or_test_id"))
			return
		}
		
		httpClient.submit(keys: keys, mobileTestId: mobileTestId, dateTestCommunicated: testResult.dateTestCommunicated) { error in
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
