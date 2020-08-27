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

extension URLRequest {
	static func submitKeysRequest(
		configuration: HTTPClient.Configuration,
		mobileTestId: BEMobileTestId,
		testResult:TestResult,
		keys: [ENTemporaryExposureKey],
		countries: [BECountry]
	) throws -> URLRequest {
		let payload = SAP_SubmissionPayload.with {
			$0.padding = self.getSubmissionPadding(for: keys)
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

		request.httpMethod = "POST"
		request.httpBody = payloadData

		return request
	}

	/// This method recreates the request body of the submit keys request with a padding that fills up to resemble
	/// a request with 14 +`n` keys. Note that the `n`parameter is currently set to 0, but can change in the future
	/// when there will be support for 15 keys.
	private static func getSubmissionPadding(for keys: [ENTemporaryExposureKey]) -> Data {
		// This parameter denotes how many keys 14 + n have to be padded.
		let n = 0
		let paddedKeysAmount = 14 + n - keys.count
		guard paddedKeysAmount > 0 else { return Data() }
		
		var byteCount = 31 * paddedKeysAmount
		
		// we can remove one byte, as an array bigger than 127 bytes will need 2 bytes to store its length
		// thereby increasing the total payload size with 1 byte
		if byteCount > 128 {
			byteCount -= 1
		}
		
		guard let data = (String.random(length: byteCount)).data(using: .ascii) else { return Data() }
		
		return data
	}
}

