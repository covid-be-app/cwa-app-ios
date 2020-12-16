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
		
		let payloadData = try getPaddedPayloadData(keys: keys, countries: countries)
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
		
		if let symptomsDate = mobileTestId.symptomsStartDate {
			request.setValue(
				symptomsDate,
				forHTTPHeaderField: "Date-Onset-Of-Symptoms"
			)
		}

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
	
	/// Is this efficient? No
	/// Does it work? Yes
	///
	/// The problem is we try to get a fixed size buffer built on something containing variable length fields,
	/// e.g. every int stored in a protobuffer can be represented in 1 or multiple bytes depending on its value.
	/// The same goes for the lengths of strings and byte buffers. So in order avoid implementing 'intelligent' code
	/// that tries to incorporate all those variables and risking forgetting one or more corner cases
	/// (since the size depends on the actual value that is stored)
	/// we simply append bytes to the result object until we arrive at the given size.
	///
	/// Worst case this means the below loop runs `wantedByteCount` amount of times, but since this call is only used
	/// when uploading keys and therefore not happens very often we don't really care about its performance. Even
	/// 700 iterations will not slow down the app in a noticeable way
	private static func getPaddedPayloadData(keys: [ENTemporaryExposureKey], countries: [BECountry]) throws -> Data {
		// padd all to 700 bytes
		let wantedByteCount = 700
		var currentByteCount = 0
		var payloadData:Data!
		var currentPaddingCount = 0
		
		while currentByteCount < wantedByteCount {
			guard let paddingData = String.random(length: currentPaddingCount).data(using: .ascii) else {
				fatalError("This should never happen")
			}
			
			let payload = SAP_SubmissionPayload.with {
				$0.requestPadding = paddingData
				$0.keys = keys.map { $0.sapKey }
				$0.visitedCountries = countries.map { $0.code2 }
				$0.origin = "BE"
				$0.consentToFederation = true
			}
			
			payloadData = try payload.serializedData()

			currentByteCount = payloadData.count
			currentPaddingCount += 1
		}
		
		return payloadData
	}
}

