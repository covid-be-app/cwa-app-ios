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

class BEHomeVaccinationInfoCellConfigurator: TableViewCellConfigurator {
	private var vaccinationInfo: BEVaccinationInfo?
	private var vaccinationInfoUpdatedAt: Date?
	
	private let updatedAtFormatter: DateFormatter

	init(vaccinationInfo: BEVaccinationInfo?, vaccinationInfoUpdatedAt: Date? ) {
		self.vaccinationInfo = vaccinationInfo
		self.vaccinationInfoUpdatedAt = vaccinationInfoUpdatedAt
		updatedAtFormatter = DateFormatter()
		updatedAtFormatter.dateStyle = .medium
		updatedAtFormatter.timeStyle = .short
	}
	
	func configure(cell: BEVaccinationInfoTableViewCell) {
		let numberFormatter = NumberFormatter()
		
		numberFormatter.numberStyle = .decimal
		
		cell.titleLabel.text = BEAppStrings.BEVaccinationInfo.title
		cell.firstDoseTextLabel.text = BEAppStrings.BEVaccinationInfo.firstDose
		cell.secondDoseTextLabel.text = BEAppStrings.BEVaccinationInfo.secondDose
		cell.thirdDoseTextLabel.text = BEAppStrings.BEVaccinationInfo.thirdDose

		guard
			let vaccinationInfo = self.vaccinationInfo,
			let vaccinationInfoUpdatedAt = self.vaccinationInfoUpdatedAt
		else {
			cell.firstDoseLabel.text = "-"
			cell.secondDoseLabel.text = "-"
			cell.thirdDoseLabel.text = "-"
			cell.lastUpdatedLabel.text = nil
			return
		}

		cell.firstDoseLabel.text = numberFormatter.string(from:NSNumber(value: vaccinationInfo.atLeastPartiallyVaccinated))
		cell.secondDoseLabel.text = numberFormatter.string(from:NSNumber(value: vaccinationInfo.fullyVaccinated))
		cell.thirdDoseLabel.text = numberFormatter.string(from:NSNumber(value: vaccinationInfo.boosterVaccinated))

		cell.lastUpdatedLabel.text = String(format:
			BEAppStrings.BEVaccinationInfo.updatedAt,
			updatedAtFormatter.string(from: vaccinationInfoUpdatedAt))
	}
	
	// MARK: Hashable

	func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(vaccinationInfo)
		hasher.combine(vaccinationInfoUpdatedAt)
	}

	static func == (lhs: BEHomeVaccinationInfoCellConfigurator, rhs: BEHomeVaccinationInfoCellConfigurator) -> Bool {
		lhs.vaccinationInfo == rhs.vaccinationInfo &&
		lhs.vaccinationInfoUpdatedAt == rhs.vaccinationInfoUpdatedAt
	}
}
