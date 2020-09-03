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

let payloadSize = 750

extension URLRequest {
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
			"application/x-protobuf",
			forHTTPHeaderField: "Content-Type"
		)
		
		let paddingData = Data(count: payloadSize - payloadData.count)
		var bodyData = Data.init()

		bodyData.append(payloadData)
		bodyData.append(paddingData)
		
		request.httpMethod = "POST"
		request.httpBody = bodyData

		return request
	}
}

