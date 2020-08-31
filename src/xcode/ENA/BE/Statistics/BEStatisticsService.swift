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

protocol BEStatisticsService {
	typealias InfectionSummaryHandler = (Result<BEInfectionSummary, Error>) -> Void
	func getInfectionSummary(completion: @escaping InfectionSummaryHandler)
}

class BEStatisticsServiceImpl : BEStatisticsService {
	
	private let client:BEHTTPClient

	private var infectionSummary:BEInfectionSummary?
	private var infectionSummaryUpdatedAt:Date?
	private let infectionSummaryUpdateInterval:TimeInterval = 3600
	
	// We use Client and not BEHTTPClient because otherwise we would need to modify the German code in quite a few places
	// We know we have a BEHTTPClient instance here, so we check for it
	// This could be done cleaner by adding the new methods to the Client protocol
	// but because we try to keep the belgian and german code separated as much as possible (for maintenance/bugfix pulls)
	// we do not do this as this requires modifying original files
	init(client:Client) {
		guard let beClient = client as? BEHTTPClient else {
			preconditionFailure("Only BE client allowed")
		}
		
		self.client = beClient
	}
	
	func getInfectionSummary(completion: @escaping InfectionSummaryHandler) {
		if let lastUpdateDate = infectionSummaryUpdatedAt, let summary = infectionSummary {
			if lastUpdateDate.timeIntervalSinceNow > -infectionSummaryUpdateInterval {
				completion(.success(summary))
				return
			}
		}
		
		client.getInfectionSummary { result in
			switch result {
			case .failure(let error):
				completion(.failure(error))
			case .success(let summary):
				self.infectionSummary = summary
				self.infectionSummaryUpdatedAt = Date()
				completion(.success(summary))
			}
		}
	}
}
