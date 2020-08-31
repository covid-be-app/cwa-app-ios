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

class BEMockExposureSubmissionService : BEExposureSubmissionService {
	var submitExposureCallback: ((@escaping ExposureSubmissionHandler) -> Void)?
	var mobileTestId: BEMobileTestId?
	
	private var keys:[ENTemporaryExposureKey]
	
	init() {
		let dayCount = 14
		let startDate = Calendar.current.date(byAdding: .day, value: -dayCount, to: Date(), wrappingComponents: true)!
		var diagnosisKeys:[ENTemporaryExposureKey] = []
		
		for x in 0..<dayCount+1 {
			let date = Calendar.current.date(byAdding: .day, value: x, to: startDate, wrappingComponents: true)!
			let key = ENTemporaryExposureKey()
			key.transmissionRiskLevel = .zero
			key.rollingPeriod = 100
			key.rollingStartNumber = ENIntervalNumber.fromDateInt(BEDateInt.fromDate(date))
			
			diagnosisKeys.append(key)
		}
		
		keys = diagnosisKeys
	}

	func retrieveDiagnosisKeys(completionHandler: @escaping BEExposureSubmissionGetKeysHandler) {
		DispatchQueue.main.async {
			completionHandler(.success(self.keys))
		}
	}
	
	func submitExposure(keys: [ENTemporaryExposureKey], countries: [BECountry], completionHandler: @escaping ExposureSubmissionHandler) {
		submitExposureCallback?(completionHandler)
	}
	
	func submitExposure(completionHandler: @escaping ExposureSubmissionHandler) {
		fatalError("no longer supported")
	}
	
	func getRegistrationToken(forKey deviceRegistrationKey: DeviceRegistrationKey, completion completeWith: @escaping RegistrationHandler) {
		fatalError("no longer supported")
	}
	
	func getTestResult(_ completeWith: @escaping TestResultHandler) {
		completeWith(.success(TestResult.positive))
	}
	
	func hasRegistrationToken() -> Bool {
		return true
	}
	
	func deleteTest() {
		
	}
	
	var devicePairingConsentAcceptTimestamp: Int64?
	
	var devicePairingSuccessfulTimestamp: Int64?
	
	func preconditions() -> ExposureManagerState {
		return ExposureManagerState(authorized: false, enabled: false, status: .unknown)
	}
	
	func acceptPairing() {
		
	}
	
	func deleteTestIfOutdated() -> Bool {
		return false
	}
	
	func getFakeTestResult(_ completeWith: @escaping TestResultHandler) {
		completeWith(.success(TestResult.positive))
	}
	
	func submitFakeExposure(completionHandler: @escaping ExposureSubmissionHandler) {
		completionHandler(nil)
	}
	
	func getFakeTestResult(_ isLast: Bool, completion: @escaping (() -> Void)) {
		completion()
	}
}
