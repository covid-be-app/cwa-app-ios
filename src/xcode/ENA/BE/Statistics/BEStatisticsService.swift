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
	typealias StatisticsHandler = (Result<(BEInfectionSummary, BEVaccinationInfo), Error>) -> Void
	
	private let client:Client

	@OpenCombine.Published private(set) var infectionSummary:BEInfectionSummary?
	@OpenCombine.Published private(set) var vaccinationInfo:BEVaccinationInfo?
	@OpenCombine.Published private(set) var updatedAt:Date?
	
	private let updateInterval:TimeInterval = 3600
	
	private var observers:Set<AnyCancellable> = []
	
	init(client: Client, store: Store) {
		self.client = client

		infectionSummary = store.infectionSummary
		vaccinationInfo = store.vaccinationInfo
		updatedAt = store.statisticsUpdatedAt
		
		$infectionSummary.assign(to: \.infectionSummary, on: store).store(in: &observers)
		$vaccinationInfo.assign(to: \.vaccinationInfo, on: store).store(in: &observers)
		$updatedAt.assign(to: \.statisticsUpdatedAt, on: store).store(in: &observers)
	}
	
	func update(completion: @escaping StatisticsHandler) {
		if let lastUpdateDate = updatedAt,
		   let summary = infectionSummary,
		   let info = vaccinationInfo
		   {
			if lastUpdateDate.timeIntervalSinceNow > -updateInterval {
				completion(.success((summary, info)))
				return
			}
		}
		
		client.getStatistics { result in
			switch result {
			case .failure(let error):
				completion(.failure(error))
			case .success(let (summary, info)):
				self.infectionSummary = summary
				self.vaccinationInfo = info
				self.updatedAt = Date()
				completion(.success((summary, info)))
			}
		}
	}
}
