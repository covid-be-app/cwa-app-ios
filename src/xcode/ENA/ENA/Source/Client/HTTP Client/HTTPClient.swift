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
import ZIPFoundation

final class HTTPClient: Client {
	// MARK: Creating
	init(
		configuration: Configuration,
		packageVerifier: @escaping SAPDownloadedPackage.Verification = SAPDownloadedPackage.Verifier().verify,
		session: URLSession = .coronaWarnSession()
	) {
		self.session = session
		self.configuration = configuration
		self.packageVerifier = packageVerifier
	}

	// MARK: Properties
	let configuration: Configuration
	
	private let session: URLSession
	private let packageVerifier: SAPDownloadedPackage.Verification

	func appConfiguration(completion: @escaping AppConfigurationCompletion) {
		session.GET(configuration.configurationURL) { [weak self] result in
			guard let self = self else { return }

			switch result {
			case let .success(response):
				guard let data = response.body else {
					completion(nil)
					return
				}
				guard response.hasAcceptableStatusCode else {
					completion(nil)
					return
				}

				guard let package = SAPDownloadedPackage(compressedData: data) else {
					logError(message: "Failed to create downloaded package for app config.")
					completion(nil)
					return
				}

				// Configuration File Signature must be checked by the application since it is not verified by the operating system
				guard self.packageVerifier(package) else {
					logError(message: "Failed to verify app config signature")
					completion(nil)
					return
				}
				completion(try? SAP_ApplicationConfiguration(serializedData: package.bin))
			case .failure:
				completion(nil)
			}
		}
	}

	func exposureConfiguration(
		completion: @escaping ExposureConfigurationCompletionHandler
	) {
		log(message: "Fetching exposureConfiguration from: \(configuration.configurationURL)")
		appConfiguration { config in
			guard let config = config else {
				completion(nil)
				return
			}
			guard config.hasExposureConfig else {
				completion(nil)
				return
			}
			completion(try? ENExposureConfiguration(from: config.exposureConfig))
		}
	}

	func availableDays(
		region: BERegion,
		completion completeWith: @escaping AvailableDaysCompletionHandler
	) {
		let url = configuration.availableDaysURL(region: region)
		log(message: "Check available days for \(region.rawValue)")
		log(message: "\(url)")

		session.GET(url) { result in
			switch result {
			case let .success(response):
				guard let data = response.body else {
					completeWith(.failure(.invalidResponse))
					return
				}
				guard response.hasAcceptableStatusCode else {
					completeWith(.failure(.invalidResponse))
					return
				}
				do {
					let decoder = JSONDecoder()
					let days = try decoder
						.decode(
							[String].self,
							from: data
						)
					log(message: "days \(days)")
					completeWith(.success(days))
				} catch {
					completeWith(.failure(.invalidResponse))
					return
				}
			case let .failure(error):
				completeWith(.failure(error))
			}
		}
	}

	func availableHours(
		day: String,
		region: BERegion,
		completion completeWith: @escaping AvailableHoursCompletionHandler
	) {
		let url = configuration.availableHoursURL(day: day, region: region)
		log(message: "Check available hours for \(day) in \(region.rawValue)")
		session.GET(url) { result in
			switch result {
			case let .success(response):
				// We accept 404 responses since this can happen in case there
				// have not been any new cases reported on that day.
				// We don't report this as an error to simplify things for the consumer.
				guard response.statusCode != 404 else {
					completeWith(.success([]))
					return
				}

				guard let data = response.body else {
					completeWith(.failure(.invalidResponse))
					return
				}

				do {
					let decoder = JSONDecoder()
					let hours = try decoder.decode([Int].self, from: data)
					log(message: "hours \(hours)")
					completeWith(.success(hours))
				} catch {
					completeWith(.failure(.invalidResponse))
					return
				}
			case let .failure(error):
				completeWith(.failure(error))
			}
		}
	}

	func getTANForExposureSubmit(forDevice registrationToken: String, completion completeWith: @escaping TANHandler) {
		let url = configuration.tanRetrievalURL

		let bodyValues = ["registrationToken": registrationToken]
		do {
			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted

			let data = try encoder.encode(bodyValues)

			session.POST(url, data) { result in
				switch result {
				case let .success(response):

					if response.statusCode == 400 {
						completeWith(.failure(.regTokenNotExist))
						return
					}
					guard response.hasAcceptableStatusCode else {
						completeWith(.failure(.serverError(response.statusCode)))
						return
					}
					guard let tanResponseData = response.body else {
						completeWith(.failure(.invalidResponse))
						logError(message: "Failed to get TAN")
						logError(message: String(response.statusCode))
						return
					}
					do {
						let decoder = JSONDecoder()
						let responseDictionary = try decoder.decode(
							[String: String].self,
							from: tanResponseData
						)
						guard let tan = responseDictionary["tan"] else {
							logError(message: "Failed to get TAN because of invalid response payload structure")
							completeWith(.failure(.invalidResponse))
							return
						}
						completeWith(.success(tan))
					} catch _ {
						logError(message: "Failed to get TAN because of invalid response payload structure")
						completeWith(.failure(.invalidResponse))
					}
				case let .failure(error):
					completeWith(.failure(error))
					logError(message: "Failed to get TAN due to error: \(error).")
				}
			}
		} catch {
			completeWith(.failure(.invalidResponse))
			return
		}
	}

	func getRegistrationToken(forKey key: String, withType type: String, completion completeWith: @escaping RegistrationHandler) {
		let url = configuration.registrationURL

		let bodyValues = ["key": key, "keyType": type]
		do {
			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted

			let data = try encoder.encode(bodyValues)

			session.POST(url, data) { result in
				switch result {
				case let .success(response):
					if response.statusCode == 400 {
						if type == "TELETAN" {
							completeWith(.failure(.teleTanAlreadyUsed))
						} else {
							completeWith(.failure(.qRAlreadyUsed))
						}
						return
					}
					guard response.hasAcceptableStatusCode else {
						completeWith(.failure(.serverError(response.statusCode)))
						return
					}
					guard let registerResponseData = response.body else {
						completeWith(.failure(.invalidResponse))
						logError(message: "Failed to register Device with invalid response")
						return
					}
	
					do {
						let decoder = JSONDecoder()
						let responseDictionary = try decoder.decode(
							[String: String].self,
							from: registerResponseData
						)
						guard let registrationToken = responseDictionary["registrationToken"] else {
							logError(message: "Failed to register Device with invalid response payload structure")
							completeWith(.failure(.invalidResponse))
							return
						}
						completeWith(.success(registrationToken))
					} catch _ {
						logError(message: "Failed to register Device with invalid response payload structure")
						completeWith(.failure(.invalidResponse))
					}
				case let .failure(error):
					completeWith(.failure(error))
					logError(message: "Failed to registerDevices due to error: \(error).")
				}
			}
		} catch {
			completeWith(.failure(.invalidResponse))
			return
		}
	}

	func fetchDay(
		_ day: String,
		region: BERegion,
		completion completeWith: @escaping DayCompletionHandler
	) {
		let url = configuration.diagnosisKeysURL(day: day, region: region)
		log(message: "Fetch day \(day) for \(region.rawValue)")
		log(message: "\(url)")

		session.GET(url) { result in
			switch result {
			case let .success(response):
				guard let dayData = response.body else {
					completeWith(.failure(.invalidResponse))
					logError(message: "Failed to download day '\(day)': invalid response")
					return
				}
				guard let package = SAPDownloadedPackage(compressedData: dayData) else {
					logError(message: "Failed to create signed package.")
					completeWith(.failure(.invalidResponse))
					return
				}
				log(message: "Fetch day \(day) for \(region.rawValue) DONE: \(dayData.count)")
				completeWith(.success(package))
			case let .failure(error):
				completeWith(.failure(error))
				logError(message: "Failed to download day '\(day)' due to error: \(error).")
			}
		}
	}

	func fetchHour(
		_ hour: Int,
		day: String,
		region: BERegion,
		completion completeWith: @escaping HourCompletionHandler
	) {
		let url = configuration.diagnosisKeysURL(day: day, hour: hour, region: region)
		log(message: "Fetch hour \(hour) for \(region.rawValue)")
		log(message: "\(url)")

		session.GET(url) { result in
			switch result {
			case let .success(response):
				guard let hourData = response.body else {
					completeWith(.failure(.invalidResponse))
					return
				}

				guard let package = SAPDownloadedPackage(compressedData: hourData) else {
					logError(message: "Failed to create signed package.")
					completeWith(.failure(.invalidResponse))
					return
				}

				log(message: "Fetch hour \(hour) for \(region.rawValue) DONE: \(hourData.count)")
				completeWith(.success(package))
			case let .failure(error):
				completeWith(.failure(error))
				logError(message: "failed to get day: \(error)")
			}
		}
	}
	
	// :BE:

	// no longer supported
	func submit(keys: [ENTemporaryExposureKey], tan: String, completion: @escaping HTTPClient.SubmitKeysCompletionHandler) {
		fatalError("Deprecated")
	}
	
	func getTestResult(forDevice registrationToken: String, completion completeWith: @escaping TestResultHandler) {
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
								log(message: "Ack finished")
							}
						} else {
							self.ackTestDownload(forDevice: BEMobileTestId.fakeRegistrationToken) {
								log(message: "Fake ack finished")
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
					log(message: "Ack succeeded")
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
		mobileTestId: BEMobileTestId?,
		testResult: TestResult?,
		isFake: Bool,
		completion: @escaping SubmitKeysCompletionHandler
	) {
		if !isFake {
			if testResult == nil || mobileTestId == nil {
				fatalError("Real requests require real test result and mobile test id")
			}
		}
		
		let mobileTestIdToUse = mobileTestId ?? BEMobileTestId.random
		let testResultToUse = testResult ?? TestResult.positive
		
		guard let request = try? URLRequest.submitKeysRequest(
			configuration: configuration,
			mobileTestId: mobileTestIdToUse,
			testResult: testResultToUse,
			keys: keys
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
	
	func getInfectionSummary(completion: @escaping InfectionSummaryHandler) {
		let url = configuration.infectionSummaryURL
		self.session.GET(url) { result in
			switch result {
			case let .success(response):
				guard response.hasAcceptableStatusCode else {
					completion(.failure(.serverError(response.statusCode)))
					return
				}
				guard let summaryResponseData = response.body else {
					completion(.failure(.invalidResponse))
					return
				}
				do {
					let decoder = JSONDecoder()
					let infectionSummary = try decoder.decode(
						BEInfectionSummary.self,
						from: summaryResponseData
					)
					completion(.success(infectionSummary))
				} catch {
					completion(.failure(.invalidResponse))
				}
			case let .failure(error):
				completion(.failure(error))
			}
		}
	}
	
	func getDynamicTexts(completion: @escaping DynamicTextsHandler) {
		let url = configuration.dynamicTextsURL
		self.session.GET(url) { result in
			switch result {
			case let .success(response):
				guard response.hasAcceptableStatusCode else {
					completion(.failure(.serverError(response.statusCode)))
					return
				}
				
				guard let responseData = response.body else {
					completion(.failure(.invalidResponse))
					return
				}
				completion(.success(responseData))
			case let .failure(error):
				completion(.failure(error))
			}
		}
	}
}

// MARK: Extensions

private extension URLRequest {
	static func submitKeysRequest(
		configuration: HTTPClient.Configuration,
		tan: String,
		keys: [ENTemporaryExposureKey]
	) throws -> URLRequest {
		let payload = SAP_SubmissionPayload.with {
			$0.keys = keys.compactMap { $0.sapKey }
		}
		let payloadData = try payload.serializedData()
		let url = configuration.submissionURL

		var request = URLRequest(url: url)

		request.setValue(
			tan,
			// TAN code associated with this diagnosis key submission.
			forHTTPHeaderField: "cwa-authorization"
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

private extension ENExposureConfiguration {
	convenience init(from riskscoreParameters: SAP_RiskScoreParameters) throws {
		self.init()
		// We are intentionally not setting minimumRiskScore.
		attenuationLevelValues = riskscoreParameters.attenuation.asArray
		daysSinceLastExposureLevelValues = riskscoreParameters.daysSinceLastExposure.asArray
		durationLevelValues = riskscoreParameters.duration.asArray
		transmissionRiskLevelValues = riskscoreParameters.transmission.asArray
	}
}

private extension SAP_RiskLevel {
	var asNumber: NSNumber {
		NSNumber(value: rawValue)
	}
}

private extension SAP_RiskScoreParameters.TransmissionRiskParameter {
	var asArray: [NSNumber] {
		[appDefined1, appDefined2, appDefined3, appDefined4, appDefined5, appDefined6, appDefined7, appDefined8].map { $0.asNumber }
	}
}

private extension SAP_RiskScoreParameters.DaysSinceLastExposureRiskParameter {
	var asArray: [NSNumber] {
		[ge14Days, ge12Lt14Days, ge10Lt12Days, ge8Lt10Days, ge6Lt8Days, ge4Lt6Days, ge2Lt4Days, ge0Lt2Days].map { $0.asNumber }
	}
}

private extension SAP_RiskScoreParameters.DurationRiskParameter {
	var asArray: [NSNumber] {
		[eq0Min, gt0Le5Min, gt5Le10Min, gt10Le15Min, gt15Le20Min, gt20Le25Min, gt25Le30Min, gt30Min].map { $0.asNumber }
	}
}

private extension SAP_RiskScoreParameters.AttenuationRiskParameter {
	var asArray: [NSNumber] {
		[gt73Dbm, gt63Le73Dbm, gt51Le63Dbm, gt33Le51Dbm, gt27Le33Dbm, gt15Le27Dbm, gt10Le15Dbm, le10Dbm].map { $0.asNumber }
	}
}
