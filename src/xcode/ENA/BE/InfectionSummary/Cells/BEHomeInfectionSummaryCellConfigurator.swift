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

class BEHomeInfectionSummaryCellConfigurator: CollectionViewCellConfigurator {
	var infectionSummary: BEInfectionSummary!
	var infectionSummaryUpdatedAt: Date!
	
	private let updatedAtFormatter: DateFormatter
	private let dateRangeFormatter: DateFormatter

	init() {
		updatedAtFormatter = DateFormatter()
		updatedAtFormatter.dateStyle = .medium
		updatedAtFormatter.timeStyle = .short
		
		dateRangeFormatter = DateFormatter()
		dateRangeFormatter.setLocalizedDateFormatFromTemplate("dd MMM")
	}
	
	func configure(cell: BEInfectionSummaryCollectionViewCell) {
		cell.titleLabel.text = BEAppStrings.BEInfectionSummary.title

		cell.averageInfectedLabel.text = String(format:BEAppStrings.BEInfectionSummary.averageInfected, infectionSummary.averageInfected, infectionSummary.averageInfectedChangePercentage)
		cell.averageHospitalisedLabel.text = String(format:BEAppStrings.BEInfectionSummary.averageHospitalised, infectionSummary.averageHospitalised, infectionSummary.averageHospitalisedChangePercentage)
		cell.averageDeceasedLabel.text = String(format:BEAppStrings.BEInfectionSummary.averageDeceased, infectionSummary.averageDeceased, infectionSummary.averageDeceasedChangePercentage)
		
		cell.lastUpdatedLabel.text = String(format:BEAppStrings.BEInfectionSummary.updatedAt, updatedAtFormatter.string(from: infectionSummaryUpdatedAt))


		guard
			let startDate = infectionSummary.startDate.dateWithoutTime,
			let endDate = infectionSummary.endDate.dateWithoutTime else {
				cell.dateRangeLabel.text = nil
				return
		}
		
		let startString = dateRangeFormatter.string(from: startDate)
		let endString = dateRangeFormatter.string(from: endDate)
		cell.dateRangeLabel.text = "\(startString) - \(endString)"
	}
	
	// MARK: Hashable

	func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(infectionSummary)
		hasher.combine(infectionSummaryUpdatedAt)
	}

	static func == (lhs: BEHomeInfectionSummaryCellConfigurator, rhs: BEHomeInfectionSummaryCellConfigurator) -> Bool {
		lhs.infectionSummary == rhs.infectionSummary &&
		lhs.infectionSummaryUpdatedAt == rhs.infectionSummaryUpdatedAt
	}
}
