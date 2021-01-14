//
// Corona-Warn-App
//
// SAP SE and all other contributors /
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

import UIKit

final class HomeFindingPositiveRiskCellConfigurator: HomeRiskCellConfigurator {

	var nextAction: (() -> Void)?

	// MARK: Configuration

	func configure(cell: HomeRiskFindingPositiveTableViewCell) {
		let dynamicTextService = BEDynamicTextService()
		let screenSections = dynamicTextService.sections(.positiveTestResultCard, section: .explanation)
		cell.delegate = self

		let title = AppStrings.Home.findingPositiveCardTitle
		let titleColor: UIColor = .enaColor(for: .textPrimary1)
		cell.configureTitle(title: title, titleColor: titleColor)

		let statusTitle = AppStrings.Home.findingPositiveCardStatusTitle
		let statusSubtitle = AppStrings.Home.findingPositiveCardStatusSubtitle
		let statusImageName = "Illu_Home_PositivTestErgebnis"
		cell.configureStatus(title: statusTitle, subtitle: statusSubtitle, titleColor: titleColor, lineColor: .enaColor(for: .riskHigh), imageName: statusImageName)

		let noteTitle = AppStrings.Home.findingPositiveCardNoteTitle
		cell.configureNoteLabel(title: noteTitle)
		let iconColor: UIColor = .enaColor(for: .riskHigh)

		let configurators: [HomeRiskImageItemViewConfigurator] = screenSections.map { section in
			guard
				let icon = section.icon,
				let text = section.text else {
				fatalError("Not suppored")
			}
			
			let item = HomeRiskImageItemViewConfigurator(title: text, titleColor: titleColor, iconImage: icon, iconTintColor: iconColor, color: .clear, separatorColor: .clear)
			item.containerInsets = .init(top: 10.0, left: 0.0, bottom: 10.0, right: 0)

			return item
		}

		cell.configureNotesRiskViews(cellConfigurators: configurators)

		let buttonTitle = AppStrings.Home.findingPositiveCardButton

		cell.configureNextButton(title: buttonTitle)

		let backgroundColor: UIColor = .enaColor(for: .background)
		cell.configureBackgroundColor(color: backgroundColor)

		setupAccessibility(cell)
	}

	func setupAccessibility(_ cell: HomeRiskFindingPositiveTableViewCell) {
		cell.titleLabel.isAccessibilityElement = false
		cell.chevronImageView.isAccessibilityElement = false
		cell.viewContainer.isAccessibilityElement = false
		cell.stackView.isAccessibilityElement = false

		cell.topContainer.isAccessibilityElement = true

		let topContainerText = cell.titleLabel.text ?? ""
		cell.topContainer.accessibilityLabel = topContainerText
		cell.topContainer.accessibilityTraits = [.button, .header]
		cell.nextButton.accessibilityIdentifier = AccessibilityIdentifiers.Home.resultCardShowResultButton
	}

	// MARK: Hashable

	func hash(into hasher: inout Swift.Hasher) {
		// this class has no stored properties, that's why hash function is empty here
	}

	static func == (lhs: HomeFindingPositiveRiskCellConfigurator, rhs: HomeFindingPositiveRiskCellConfigurator) -> Bool {
		// instances of this class have no differences between each other
		true
	}
}

extension HomeFindingPositiveRiskCellConfigurator: HomeRiskFindingPositiveTableViewCellDelegate {
	func nextButtonTapped(cell: HomeRiskFindingPositiveTableViewCell) {
		nextAction?()
	}
}
