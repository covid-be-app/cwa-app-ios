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

import Foundation

// :BE: endpoints for each build target

extension HTTPClient {

	struct Configuration {

		// swiftlint:disable force_unwrapping
		static let distributionBaseURL = URL(string: "https://c19distcdn-\(BEEnvironment.current.urlSuffix()).ixor.be")!
		static let submissionBaseURL = URL(string: "https://c19-submission-\(BEEnvironment.current.urlSuffix()).ixor.be")!
		static let verificationBaseURL = URL(string: "https://c19-verification-\(BEEnvironment.current.urlSuffix()).ixor.be")!
		static let statisticsBaseURL = URL(string: "https://c19statcdn-\(BEEnvironment.current.urlSuffix()).ixor.be")!
		static let dynamicTextsURL = URL(string: "https://coronalert-\(BEEnvironment.current.urlSuffix()).ixor.be")!
		// swiftlint:enable force_unwrapping
		
		// MARK: Default Instances

		static let backendBaseURLs = Configuration(
			apiVersion: "v1",
			
			// :BE: use BE
			country: "BE",
			endpoints: Configuration.Endpoints(
				distribution: .init(
					baseURL: distributionBaseURL,
					requiresTrailingSlash: false
				),
				submission: .init(
					baseURL: submissionBaseURL,
					requiresTrailingSlash: false
				),
				verification: .init(
					baseURL: verificationBaseURL,
					requiresTrailingSlash: false
				),
				
				// :BE: add statistics
				statistics: .init(
					baseURL: statisticsBaseURL,
					requiresTrailingSlash: false
				),
				dynamicTexts: .init(
					baseURL: dynamicTextsURL,
					requiresTrailingSlash: false
				)
			)
		)

		// MARK: Properties

		let apiVersion: String
		let country: String
		let endpoints: Endpoints

		var diagnosisKeysURL: URL {
			endpoints
				.distribution
				.appending(
					"version",
					apiVersion,
					"diagnosis-keys",
					"country",
					country
				)
		}

		var availableDaysURL: URL {
			endpoints
				.distribution
				.appending(
					"version",
					apiVersion,
					"diagnosis-keys",
					"country",
					country,
					"date"
				)
		}

		func availableHoursURL(day: String) -> URL {
			endpoints
				.distribution
				.appending(
					"version",
					apiVersion,
					"diagnosis-keys",
					"country",
					country,
					"date",
					day,
					"hour"
				)
		}

		func diagnosisKeysURL(day: String, hour: Int) -> URL {
			endpoints
				.distribution
				.appending(
					"version",
					apiVersion,
					"diagnosis-keys",
					"country",
					country,
					"date",
					day,
					"hour",
					String(hour)
				)
		}

		func diagnosisKeysURL(day: String) -> URL {
			endpoints
				.distribution
				.appending(
					"version",
					apiVersion,
					"diagnosis-keys",
					"country",
					country,
					"date",
					day
				)
		}

		var configurationURL: URL {
			endpoints
				.distribution
				.appending(
					"version",
					apiVersion,
					"configuration",
					"country",
					country,
					"app_config"
				)
		}

		// :BE: change endpoint url
		var submissionURL: URL {
			endpoints
				.submission
				.appending(
					"submission-api",
					"version",
					apiVersion,
					"diagnosis-keys"
				)
		}

		var registrationURL: URL {
			endpoints
				.verification
				.appending(
					"version",
					apiVersion,
					"registrationToken"
				)
		}

		// :BE: change endpoint url
		var testResultURL: URL {
			endpoints
				.verification
				.appending(
					"verification-api",
					"version",
					apiVersion,
					"testresult",
					"poll"
				)
		}

		// :BE: add ack url
		var ackTestResultURL: URL {
			endpoints
				.verification
				.appending(
					"verification-api",
					"version",
					apiVersion,
					"testresult",
					"ack"
				)
		}

		var tanRetrievalURL: URL {
			endpoints
				.verification
				.appending(
					"version",
					apiVersion,
					"tan"
				)
		}
		
		// :BE: add statistics
		
		var infectionSummaryURL: URL {
			endpoints
				.statistics
				.appending(
					"statistics",
					"statistics.json"
				)
		}
		
		var dynamicTextsURL: URL {
			endpoints
				.dynamicTexts
				.appending(
					"dynamictext",
					"dynamicTextsV2.json"
			)
		}
	}
}

extension HTTPClient.Configuration {
	struct Endpoint {
		// MARK: Creating an Endpoint

		init(
			baseURL: URL,
			requiresTrailingSlash: Bool,
			requiresTrailingIndex _: Bool = true
		) {
			self.baseURL = baseURL
			self.requiresTrailingSlash = requiresTrailingSlash
			requiresTrailingIndex = false
		}

		// MARK: Properties

		let baseURL: URL
		let requiresTrailingSlash: Bool
		let requiresTrailingIndex: Bool

		// MARK: Working with an Endpoint

		func appending(_ components: String...) -> URL {
			let url = components.reduce(baseURL) { result, component in
				result.appendingPathComponent(component, isDirectory: self.requiresTrailingSlash)
			}
			if requiresTrailingIndex {
				return url.appendingPathComponent("index", isDirectory: false)
			}
			return url
		}
	}
}

extension HTTPClient.Configuration {
	struct Endpoints {
		let distribution: Endpoint
		let submission: Endpoint
		let verification: Endpoint
		
		// :BE: add statistics
		let statistics: Endpoint
		let dynamicTexts: Endpoint
	}
}
