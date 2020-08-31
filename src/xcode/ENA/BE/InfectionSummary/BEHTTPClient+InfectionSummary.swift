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

extension BEHTTPClient {
	typealias InfectionSummaryHandler = (Result<BEInfectionSummary, Failure>) -> Void

	func getInfectionSummary(completion: @escaping InfectionSummaryHandler) {
		let url = configuration.infectionSummaryURL
		
		session.GET(url) { result in
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
}
