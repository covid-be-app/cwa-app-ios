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
	
	@discardableResult func generateMobileTestId(_ symptomsDate: Date?) -> BEMobileTestId
	
	func retrieveDiagnosisKeys(completionHandler: @escaping BEExposureSubmissionGetKeysHandler)
	func finalizeSubmissionWithoutKeys()
	func submitExposure(keys:[ENTemporaryExposureKey],countries:[BECountry], completionHandler: @escaping ExposureSubmissionHandler)
	func submitFakeExposure(completionHandler: @escaping ExposureSubmissionHandler)
	
	func deleteMobileTestIdIfOutdated() -> Bool
	
	// remove the test result X time after it has been shown (default = 48h)
	func deleteTestResultIfOutdated()
	
	// stores the fact that the test result was shown
	func setTestResultShownOnScreen()
	
	func getFakeTestResult(completion: @escaping(() -> Void))
}

class BEExposureSubmissionServiceImpl : ENAExposureSubmissionService, BEExposureSubmissionService {
	
	private(set) override var mobileTestId:BEMobileTestId? {
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
			} else {
				store.registrationToken = nil
				store.testResult = nil
				store.devicePairingSuccessfulTimestamp = nil
			}
		}
	}
	
	func generateMobileTestId(_ symptomsDate: Date?) -> BEMobileTestId {
		let id = BEMobileTestId.generate(symptomsDate)
		self.mobileTestId = id
		
		return id
	}

	override func deleteTest() {
		super.deleteTest()
		self.mobileTestId = nil
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
					
					
					// upload fake TEKs after negative so someone watching network traffic can't tell if it's a positive or negative test result
					if testResult.result == .negative {
						// introduce a random delay between 5 and 15 seconds
						let delay = Double(5 + Int(arc4random_uniform(10)))
						
						DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
							self.submitFakeExposure { _ in
								log(message:"Fake key upload after negative test result done")
							}
						}
					}
				}
				completeWith(.success(testResult))
			}
		}
	}

	func getFakeTestResult(completion: @escaping(() -> Void)) {
		client.getTestResult(forDevice: BEMobileTestId.fakeRegistrationToken) { _ in
			completion()
		}
	}

	func deleteMobileTestIdIfOutdated() -> Bool {
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
	
	func deleteTestResultIfOutdated() {
		guard let _ = store.testResult,
		let timestamp = store.testResultReceivedTimeStamp else {
			return
		}

		// if this is set we know the user has opened the test result screen
		// so we can delete after 48h
		if let deletionDate = store.deleteTestResultAfterDate {
			if deletionDate < Date() {
				deleteTest()
				log(message:"Deleted test result after having shown it to the user")
				return
			}
		} else {
			// if the user didn't open the test result screen for a long time (default = 7 days after receiving the test result) we will also delete the test result
			let endDate = Date(timeIntervalSince1970: TimeInterval(timestamp)).addingTimeInterval(store.deleteTestResultAfterTimeInterval)

			if endDate < Date() {
				deleteTest()
				log(message: "Deleted test result because it is too old")
				return
			}
		}
	}
	
	func setTestResultShownOnScreen() {
		guard let testResult = store.testResult else {
			return
		}
		
		// we don't care about pending
		if testResult.result == .pending {
			return
		}
	
		// delete 48 hours after being shown for the first time
		if store.deleteTestResultAfterDate == nil {
			store.deleteTestResultAfterDate = Date().addingTimeInterval(48 * 60 * 60)
		}
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
	
	func finalizeSubmissionWithoutKeys() {
		self.submitExposureCleanup()
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
	
	func submitFakeExposure(completionHandler: @escaping ExposureSubmissionHandler) {
		let country = BECountry(code3: "BEL", name: ["nl":"België","fr":"Belgique","en":"Belgium","de":"Belgien"])

		client.submit(
			keys: [ENTemporaryExposureKey.random(Date())],
			countries: [country],
			mobileTestId: nil,
			testResult: nil,
			isFake: true
			) { error in
			if let error = error {
				logError(message: "Error while submiting diagnosis keys: \(error.localizedDescription)")
				completionHandler(self.parseError(error))
				return
			}
			completionHandler(nil)
		}
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
		
		client.submit(
			keys: keys,
			countries:countries,
			mobileTestId: mobileTestId,
			testResult: testResult,
			isFake: false) { error in
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
