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
		fatalError()
	}
	
	func submit(
		keys: [ENTemporaryExposureKey],
		countries: [BECountry],
		mobileTestId: BEMobileTestId,
		dateTestCommunicated:String,
		completion: @escaping SubmitKeysCompletionHandler
	) {
		guard let request = try? URLRequest.submitKeysRequest(
			configuration: configuration,
			mobileTestId: mobileTestId,
			dateTestCommunicated: dateTestCommunicated,
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
}

private extension URLRequest {
	static func submitKeysRequest(
		configuration: HTTPClient.Configuration,
		mobileTestId: BEMobileTestId,
		dateTestCommunicated:String,
		keys: [ENTemporaryExposureKey]
	) throws -> URLRequest {
		let payload = SAP_SubmissionPayload.with {
			$0.keys = keys.compactMap { $0.sapKey }
		}
		let payloadData = try payload.serializedData()
		let url = configuration.submissionURL

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
			dateTestCommunicated,
			forHTTPHeaderField: "Date-Test-Communicated"
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

