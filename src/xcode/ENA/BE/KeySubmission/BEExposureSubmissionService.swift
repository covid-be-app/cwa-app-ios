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

protocol BEExposureSubmissionService : ExposureSubmissionService {
	typealias BEExposureSubmissionGetKeysHandler = (Result<[ENTemporaryExposureKey], ExposureSubmissionError>) -> Void
	
	var httpClient:BEHTTPClient { get }
	var mobileTestId:BEMobileTestId? { get set }
	
	func retrieveDiagnosisKeys(completionHandler: @escaping BEExposureSubmissionGetKeysHandler)
	func submitExposure(keys:[ENTemporaryExposureKey],countries:[BECountry], completionHandler: @escaping ExposureSubmissionHandler)
	
	func deleteTestIfOutdated() -> Bool
}

class BEExposureSubmissionServiceImpl : ENAExposureSubmissionService, BEExposureSubmissionService {
	
	lazy var httpClient:BEHTTPClient = {
		guard let beClient = client as? BEHTTPClient else {
			fatalError("Wrong subclass")
		}
		
		return beClient
	}()
	
	var mobileTestId:BEMobileTestId? {
		get {
			return store.mobileTestId
		}
		set {
			store.mobileTestId = newValue

			if newValue != nil {
				print(newValue!)
				store.registrationToken = newValue!.registrationToken
				// set as pending so the home view controller shows the right state
				store.testResult = .pending
				store.devicePairingSuccessfulTimestamp = Int64(Date().timeIntervalSince1970)
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
		fatalError("Deprecated")
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
	
	func deleteTestIfOutdated() -> Bool {
		guard let mobileTestId = store.mobileTestId else {
			fatalError("No mobile test id present")
		}
		
		let endDate = mobileTestId.creationDate.addingTimeInterval(store.deleteMobileTestIdAfterTimeInterval)
		
		if endDate < Date() {
			deleteTest()
			log(message: "Deleted outdated test request")
			return true
		}
		
		return false
	}
	
	func retrieveDiagnosisKeys(completionHandler: @escaping BEExposureSubmissionGetKeysHandler) {
		guard
			let mobileTestId = store.mobileTestId,
			let testResult = store.testResult else {
				completionHandler(.failure(ExposureSubmissionError.internal))
				return
		}
		
		let dateTestCommunicatedInt = testResult.dateTestCommunicated.dateInt
		let datePatientInfectiousInt = mobileTestId.datePatientInfectious.dateInt

		diagnosiskeyRetrieval.getKeysInDateRange(startDate: datePatientInfectiousInt, endDate: dateTestCommunicatedInt) { keys,error in
			
			if error == nil && keys == nil {
				completionHandler(.failure(.noKeys))
				return
			}
			
			if let error = error {
				logError(message: "Error while retrieving diagnosis keys: \(error.localizedDescription)")
				completionHandler(.failure(self.parseError(error)))
				return
			}

			var processedKeys = keys!
			processedKeys.processedForSubmission()
			completionHandler(.success(processedKeys))
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
		fatalError("Deprecated")
	}

	private func submit(keys: [ENTemporaryExposureKey], countries:[BECountry], completion: @escaping ExposureSubmissionHandler) {
		
		guard
			let testResult = store.testResult,
			let mobileTestId = store.mobileTestId
		else {
			completion(.other("no_test_result_or_test_id"))
			return
		}
		
		httpClient.submit(
			keys: keys,
			countries:countries,
			mobileTestId: mobileTestId,
			testResult: testResult) { error in
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
