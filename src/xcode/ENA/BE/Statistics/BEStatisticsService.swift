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
import OpenCombine

class BEStatisticsService {
	typealias InfectionSummaryHandler = (Result<BEInfectionSummary, Error>) -> Void
	
	private let client:Client

	@OpenCombine.Published private(set) var infectionSummary:BEInfectionSummary?
	@OpenCombine.Published private(set) var infectionSummaryUpdatedAt:Date?
	
	private let infectionSummaryUpdateInterval:TimeInterval = 3600
	
	private var observers:Set<AnyCancellable> = []
	
	init(client: Client, store: Store) {
		self.client = client

		infectionSummary = store.infectionSummary
		infectionSummaryUpdatedAt = store.infectionSummaryUpdatedAt
		
		$infectionSummary.assign(to: \.infectionSummary, on: store).store(in: &observers)
		$infectionSummaryUpdatedAt.assign(to: \.infectionSummaryUpdatedAt, on: store).store(in: &observers)
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
