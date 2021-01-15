// Corona-Warn-App
//
// SAP SE and all other contributors
//
// Modified by Devside SRL
//
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

import ExposureNotification
import Foundation

enum DeviceRegistrationKey {
	case teleTan(String)
	case guid(String)
}

// :BE: replaced TestResult with a more complex structure
// :BE: added access to mobile test id

protocol ExposureSubmissionService: class {
	typealias ExposureSubmissionHandler = (_ error: ExposureSubmissionError?) -> Void
	typealias RegistrationHandler = (Result<String, ExposureSubmissionError>) -> Void
	typealias TestResultHandler = (Result<TestResult, ExposureSubmissionError>) -> Void
	typealias TANHandler = (Result<String, ExposureSubmissionError>) -> Void

	func getRegistrationToken(
		forKey deviceRegistrationKey: DeviceRegistrationKey,
		completion completeWith: @escaping RegistrationHandler
	)
	func getTestResult(_ completeWith: @escaping TestResultHandler)
	func hasRegistrationToken() -> Bool
	func deleteTest()
	var devicePairingSuccessfulTimestamp: Int64? { get }
	var mobileTestId: BEMobileTestId? { get }
	func preconditions() -> ExposureManagerState
}

class ENAExposureSubmissionService: ExposureSubmissionService {

	let diagnosiskeyRetrieval: DiagnosisKeysRetrieval
	let client: Client
	let store: Store
	
	private(set) var devicePairingSuccessfulTimestamp: Int64? {
		get { self.store.devicePairingSuccessfulTimestamp }
		set { self.store.devicePairingSuccessfulTimestamp = newValue }
	}
	
	var mobileTestId: BEMobileTestId? {
		self.store.mobileTestId
	}

	init(diagnosiskeyRetrieval: DiagnosisKeysRetrieval, client: Client, store: Store) {
		self.diagnosiskeyRetrieval = diagnosiskeyRetrieval
		self.client = client
		self.store = store
	}

	func hasRegistrationToken() -> Bool {
		guard let token = store.registrationToken, !token.isEmpty else {
			return false
		}
		return true
	}

	func deleteTest() {
		store.registrationToken = nil
		store.testResult = nil
		store.deleteTestResultAfterDate = nil
		store.testResultReceivedTimeStamp = nil
		store.devicePairingSuccessfulTimestamp = nil
		store.isAllowedToSubmitDiagnosisKeys = false
	}

	/// This method gets the test result based on the registrationToken that was previously
	/// received, either from the TAN or QR Code flow. After successful completion,
	/// the timestamp of the last received test is updated.
	func getTestResult(_ completeWith: @escaping TestResultHandler) {
		
		// :BE: implemented in subclass
		fatalError("Deprecated")
	}

	/// Stores the provided key, retrieves the registration token and deletes the key.
	func getRegistrationToken(
		forKey deviceRegistrationKey: DeviceRegistrationKey,
		completion completeWith: @escaping RegistrationHandler
	) {
		let (key, type) = getKeyAndType(for: deviceRegistrationKey)
		
		print("key = \(key)")
		
		client.getRegistrationToken(forKey: key, withType: type) { result in
			switch result {
			case let .failure(error):
				completeWith(.failure(self.parseError(error)))
			case let .success(registrationToken):
				self.store.registrationToken = registrationToken
				self.store.testResultReceivedTimeStamp = nil
				self.store.devicePairingSuccessfulTimestamp = Int64(Date().timeIntervalSince1970)
				completeWith(.success(registrationToken))
			}
		}
	}

	private func getTANForExposureSubmit(
		hasConsent: Bool,
		completion completeWith: @escaping TANHandler
	) {
		// alert+ store consent+ clientrequest

		guard let token = store.registrationToken else {
			completeWith(.failure(.noRegistrationToken))
			return
		}

		client.getTANForExposureSubmit(forDevice: token) { result in
			switch result {
			case let .failure(error):
				completeWith(.failure(self.parseError(error)))
			case let .success(tan):
				self.store.tan = tan
				completeWith(.success(tan))
			}
		}
	}

	private func getKeyAndType(for key: DeviceRegistrationKey) -> (String, String) {
		switch key {
		case let .guid(guid):
			return (ENAHasher.sha256(guid), "GUID")
		case let .teleTan(teleTan):
			// teleTAN should NOT be hashed, is for short time
			// usage only.
			return (teleTan, "TELETAN")
		}
	}

	// This method removes all left over persisted objects part of the
	// `submitExposure` flow. Removes the registrationToken,
	// and isAllowedToSubmitDiagnosisKeys.

	// :BE: remove private so we can access in subclass
	func submitExposureCleanup() {
		store.registrationToken = nil
		store.mobileTestId = nil
		store.testResult = nil
		store.isAllowedToSubmitDiagnosisKeys = false
		store.lastSuccessfulSubmitDiagnosisKeyTimestamp = Int64(Date().timeIntervalSince1970)
		log(message: "Exposure submission cleanup.")
	}

	/// This method attempts to parse all different types of incoming errors, regardless
	/// whether internal or external, and transform them to an `ExposureSubmissionError`
	/// used for interpretation in the frontend.
	/// If the error cannot be parsed to the expected error/failure types `ENError`, `ExposureNotificationError`,
	/// `ExposureNotificationError`, `SubmissionError`, or `URLSession.Response.Failure`,
	/// an unknown error is returned. Therefore, if this method returns `.unknown`,
	/// examine the incoming `Error` closely.
	
	// :BE: remove private so we can access in subclass
	func parseError(_ error: Error) -> ExposureSubmissionError {

		if let enError = error as? ENError {
			return enError.toExposureSubmissionError()
		}

		if let exposureNotificationError = error as? ExposureNotificationError {
			return exposureNotificationError.toExposureSubmissionError()
		}

		if let submissionError = error as? SubmissionError {
			return submissionError.toExposureSubmissionError()
		}

		if let urlFailure = error as? URLSession.Response.Failure {
			return urlFailure.toExposureSubmissionError()
		}

		return .unknown
	}

	func preconditions() -> ExposureManagerState {
		diagnosiskeyRetrieval.preconditions()
	}
}

enum ExposureSubmissionError: Error, Equatable {
	case other(String)
	case noRegistrationToken
	case enNotEnabled
	case notAuthorized
	case noKeys
	case noConsent
	case noExposureConfiguration
	case invalidTan
	case invalidResponse
	case noResponse
	case teleTanAlreadyUsed
	case qRAlreadyUsed
	case regTokenNotExist
	case serverError(Int)
	case unknown
	case httpError(String)
	case `internal`
	case unsupported
	case rateLimited
}

extension ExposureSubmissionError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case let .serverError(code):
			return "\(AppStrings.ExposureSubmissionError.other)\(code)\(AppStrings.ExposureSubmissionError.otherend)"
		case let .httpError(desc):
			return "\(AppStrings.ExposureSubmissionError.httpError)\n\(desc)"
		case .invalidTan:
			return AppStrings.ExposureSubmissionError.invalidTan
		case .enNotEnabled:
			return AppStrings.ExposureSubmissionError.enNotEnabled
		case .notAuthorized:
			return AppStrings.ExposureSubmissionError.notAuthorized
		case .noRegistrationToken:
			return AppStrings.ExposureSubmissionError.noRegistrationToken
		case .invalidResponse:
			return AppStrings.ExposureSubmissionError.invalidResponse
		case .noResponse:
			return AppStrings.ExposureSubmissionError.noResponse
		case .noExposureConfiguration:
			return AppStrings.ExposureSubmissionError.noConfiguration
		case .qRAlreadyUsed:
			return AppStrings.ExposureSubmissionError.qrAlreadyUsed
		case .teleTanAlreadyUsed:
			return AppStrings.ExposureSubmissionError.teleTanAlreadyUsed
		case .regTokenNotExist:
			return AppStrings.ExposureSubmissionError.regTokenNotExist
		case .noKeys:
			return AppStrings.ExposureSubmissionError.noKeys
		case .internal:
			return AppStrings.Common.enError11Description
		case .unsupported:
			return AppStrings.Common.enError5Description
		case .rateLimited:
			return AppStrings.Common.enError13Description
		case let .other(desc):
			return  "\(AppStrings.ExposureSubmissionError.other)\(desc)\(AppStrings.ExposureSubmissionError.otherend)"
		case .unknown:
			return AppStrings.ExposureSubmissionError.unknown
		default:
			logError(message: "\(self)")
			return AppStrings.ExposureSubmissionError.defaultError
		}
	}
}
