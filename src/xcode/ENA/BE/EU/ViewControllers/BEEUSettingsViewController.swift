//
// 🦠 Corona-Warn-App
//

import Foundation
import Combine
import UIKit

class BEEUSettingsViewController: DynamicTableViewController {

	init() {
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View life cycle methods.

	override func viewDidLoad() {
		super.viewDidLoad()
		setupView()
	}

	// MARK: - View setup methods.

	private func setupView() {
		view.backgroundColor = .enaColor(for: .background)
		setupTableView()
		setupBackButton()
	}

	private func setupTableView() {
		tableView.separatorStyle = .none
		dynamicTableViewModel = DynamicTableViewModel([
			.section(
				header: .image(UIImage(named: "Illu_EU_Interop"),
							   accessibilityLabel: AppStrings.ExposureSubmissionWarnOthers.accImageDescription,
							   accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionWarnOthers.accImageDescription,
							   height: 250),
				cells: [
					.space(height: 8),
					.title1(
						text: BEAppStrings.BEExposureNotificationSettings.euTitle,
						accessibilityIdentifier: ""
					),
					.space(height: 8),
					.body(text: BEAppStrings.BEExposureNotificationSettings.euDescription1,
						  accessibilityIdentifier: ""
					),
					.space(height: 8),
					.body(text: BEAppStrings.BEExposureNotificationSettings.euDescription2,
						  accessibilityIdentifier: ""
					),
					.space(height: 8),
					.headline(
						text: BEAppStrings.BEExposureNotificationSettings.euDescription3,
						accessibilityIdentifier: ""
					),
					.space(height: 16)

			]),
			countries(),
			.section(
				cells: [
					.space(height: 8),
					.body(text: BEAppStrings.BEExposureNotificationSettings.euDescription4,
						  accessibilityIdentifier: ""
					),
					.space(height: 16)
			])
		])
			
			
			
		tableView.register(
			DynamicTableViewIconCell.self,
			forCellReuseIdentifier: CustomCellReuseIdentifiers.flagCell.rawValue
		)

		tableView.register(
			DynamicTableViewRoundedCell.self,
			forCellReuseIdentifier: CustomCellReuseIdentifiers.roundedCell.rawValue
		)
	}
}

extension BEEUSettingsViewController {
	enum CustomCellReuseIdentifiers: String, TableViewCellReuseIdentifiers {
		case flagCell
		case roundedCell
	}

	func countries() -> DynamicSection {
		let dynamicTextService = BEDynamicTextService()
		let countries = dynamicTextService.sections(.participatingCountries, section: .list)
		let cells = countries.compactMap { DynamicCell.euCell(country: $0) }

		return DynamicSection.section(
			separators: true,
			cells: cells
		)
	}
}

extension DynamicCell {
	static func euCell(country: BEDynamicTextScreenSection) -> Self? {
		guard
			let icon = country.icon,
			let text = country.text else {
			return nil
		}
			  
		return .icon(icon,
			  text: text,
			  tintColor: nil,
			  style: .body,
			  iconWidth: 32,
			  action: .none,
			  configure: { _, cell, _ in
			cell.contentView.layoutMargins.left = 32
			cell.contentView.layoutMargins.right = 32
		})
	}
}
