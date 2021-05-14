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

extension BEInfectionSummary {

	var averageInfectedChangePercentageString:String {
		return deltaText(self.averageInfectedChangePercentage)
	}

	var averageDeceasedChangePercentageString:String {
		return deltaText(self.averageDeceasedChangePercentage)
	}

	var averageHospitalisedChangePercentageString:String {
		return deltaText(self.averageHospitalisedChangePercentage)
	}

	private func deltaText(_ number:Int) -> String {
		let deltaString = "(%@%d%%)"
		
		return String(format: deltaString, signForNumber(number), number)
	}

	// Only show a + if positive, for the other cases the number itself will contain the sign
	private func signForNumber(_ number:Int) -> String {
		if number > 0 {
			return "+"
		}
		
		return ""
	}
}

class BEHomeInfectionSummaryCellConfigurator: TableViewCellConfigurator {
	var infectionSummary: BEInfectionSummary?
	var infectionSummaryUpdatedAt: Date?
	
	private let updatedAtFormatter: DateFormatter
	private let dateRangeFormatter: DateFormatter

	init() {
		updatedAtFormatter = DateFormatter()
		updatedAtFormatter.dateStyle = .medium
		updatedAtFormatter.timeStyle = .short
		
		dateRangeFormatter = DateFormatter()
		dateRangeFormatter.locale = NSLocale.current
		dateRangeFormatter.setLocalizedDateFormatFromTemplate("dd MMM")
	}
	
	func configure(cell: BEInfectionSummaryTableViewCell) {
		cell.titleLabel.text = BEAppStrings.BEInfectionSummary.title

		guard
			let infectionSummary = self.infectionSummary,
			let infectionSummaryUpdatedAt = self.infectionSummaryUpdatedAt
		else {
			cell.averageInfectedLabel.text = nil
			cell.averageHospitalisedLabel.text = nil
			cell.averageDeceasedLabel.text = nil
			cell.lastUpdatedLabel.text = nil
			cell.dateRangeLabel.text = BEAppStrings.BEInfectionSummary.notAvailable
			cell.averagesView.isHidden = true
			
			return
		}
		
		cell.averagesView.isHidden = false
		
		cell.averageInfectedLabel.text = "\(String(format: BEAppStrings.BEInfectionSummary.averageInfected, infectionSummary.averageInfected)) \(infectionSummary.averageInfectedChangePercentageString)"
		
		cell.averageHospitalisedLabel.text = "\(String(format: BEAppStrings.BEInfectionSummary.averageHospitalised, infectionSummary.averageHospitalised)) \(infectionSummary.averageHospitalisedChangePercentageString)"
		
		cell.averageDeceasedLabel.text = "\(String(format: BEAppStrings.BEInfectionSummary.averageDeceased, infectionSummary.averageDeceased)) \(infectionSummary.averageDeceasedChangePercentageString)"
		
		cell.lastUpdatedLabel.text = String(format:
			BEAppStrings.BEInfectionSummary.updatedAt,
			updatedAtFormatter.string(from: infectionSummaryUpdatedAt))


		guard
			let startDate = infectionSummary.startDate.dateWithoutTime,
			let endDate = infectionSummary.endDate.dateWithoutTime else {
				cell.dateRangeLabel.text = nil
				return
		}
		
		let startString = dateRangeFormatter.string(from: startDate)
		let endString = dateRangeFormatter.string(from: endDate)
		
		cell.dateRangeLabel.text = "\(BEAppStrings.BEInfectionSummary.forWeek) \(startString) - \(endString)"
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
