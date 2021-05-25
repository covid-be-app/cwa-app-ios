// Corona-Warn-App
//
// SAP SE and all other contributors
//
// Modified by Devside SRL
//
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

import Foundation
import UIKit

extension ExposureDetectionViewController {
	func dynamicTableViewModel(for riskLevel: RiskLevel, isTracingEnabled: Bool) -> DynamicTableViewModel {
		if !isTracingEnabled {
			return offModel
		}

		switch riskLevel {
		case .unknownInitial: return unknownRiskModel
		case .unknownOutdated: return outdatedRiskModel
		case .inactive: return offModel
		case .low: return lowRiskModel
		case .increased: return highRiskModel
		}
	}
}

// MARK: - Supported Header Types

private extension DynamicHeader {
	static func backgroundSpace(height: CGFloat) -> DynamicHeader {
		.space(height: height, color: .enaColor(for: .background))
	}

	static func riskTint(height _: CGFloat) -> DynamicHeader {
		.custom { viewController in
			let view = UIView()
			let heightConstraint = view.heightAnchor.constraint(equalToConstant: 16)
			heightConstraint.priority = .defaultHigh
			heightConstraint.isActive = true
			view.backgroundColor = (viewController as? ExposureDetectionViewController)?.state.riskTintColor
			return view
		}
	}
}

// MARK: - Supported Cell Types

extension DynamicCell {

	private static let relativeDateTimeFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.doesRelativeDateFormatting = true
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		return formatter
	}()

	private static func exposureDetectionCell(_ identifier: TableViewCellReuseIdentifiers, action: DynamicAction = .none, accessoryAction: DynamicAction = .none, configure: GenericCellConfigurator<ExposureDetectionViewController>? = nil) -> DynamicCell {
		.custom(withIdentifier: identifier, action: action, accessoryAction: accessoryAction, configure: configure)
	}

	static func risk(hasSeparator: Bool = true, configure: @escaping GenericCellConfigurator<ExposureDetectionViewController>) -> DynamicCell {
		.exposureDetectionCell(ExposureDetectionViewController.ReusableCellIdentifier.risk) { viewController, cell, indexPath in
			let state = viewController.state
			cell.contentView.backgroundColor = state.riskTintColor


			var tintColor: UIColor = state.isTracingEnabled ? .enaColor(for: .textContrast) : .enaColor(for: .riskNeutral)

			if state.riskLevel == .unknownOutdated { tintColor = .enaColor(for: .riskNeutral) }
			if state.riskLevel == .inactive { tintColor = .enaColor(for: .riskNeutral) }

			cell.tintColor = tintColor

			cell.textLabel?.textColor = state.riskContrastColor
			if let cell = cell as? ExposureDetectionRiskCell {
				cell.separatorView.isHidden = (indexPath.row == 0) || !hasSeparator
				cell.separatorView.backgroundColor = state.isTracingEnabled ? .enaColor(for: .hairlineContrast) : .enaColor(for: .hairline)
			}
			configure(viewController, cell, indexPath)
		}
	}

	static func riskLastRiskLevel(hasSeparator: Bool = true, text: String, image: UIImage?) -> DynamicCell {
		.risk(hasSeparator: hasSeparator) { viewController, cell, _ in
			let state = viewController.state
			cell.textLabel?.text = String(format: text, state.actualRiskText)
			cell.imageView?.image = image
		}
	}

	static func riskContacts(text: String, image: UIImage?) -> DynamicCell {
		.risk { viewController, cell, _ in
			let state = viewController.state
			let risk = state.risk
			cell.textLabel?.text = String(format: text, risk?.details.numberOfExposures ?? 0)
			cell.imageView?.image = image
		}
	}

	static func riskLastExposure(text: String, image: UIImage?) -> DynamicCell {
		.risk { viewController, cell, _ in
			// :BE: offsets if not calculated today, to reflect the correct number of days since last exposure
			let daysSinceLastExposure = viewController.state.risk?.details.calendarDaysSinceLastExposure ?? 0
			cell.textLabel?.text = .localizedStringWithFormat(text, daysSinceLastExposure)
			cell.imageView?.image = image
		}
	}

	static func riskStored(activeTracing: ActiveTracing, imageName: String) -> DynamicCell {
		.risk { viewController, cell, _ in
			let state = viewController.state
			var numberOfDaysStored = state.risk?.details.numberOfDaysWithActiveTracing ?? 0
			cell.textLabel?.text = activeTracing.localizedDuration
			if numberOfDaysStored < 0 { numberOfDaysStored = 0 }
			if numberOfDaysStored > 13 {
				cell.imageView?.image = UIImage(named: "Icons_TracingCircleFull - Dark")
			} else {
				cell.imageView?.image = UIImage(named: String(format: imageName, numberOfDaysStored))
			}
		}
	}

	static func riskRefreshed(text: String, image: UIImage?) -> DynamicCell {
		.risk { viewController, cell, _ in
			var valueText: String
			if let date: Date = viewController.state.risk?.details.exposureDetectionDate {
				valueText = relativeDateTimeFormatter.string(from: date)
			} else {
				valueText = AppStrings.ExposureDetection.refreshedNever
			}

			cell.textLabel?.text = String(format: text, valueText)
			cell.imageView?.image = image
		}
	}

	static func riskText(text: String) -> DynamicCell {
		.exposureDetectionCell(ExposureDetectionViewController.ReusableCellIdentifier.riskText) { viewController, cell, _ in
			let state = viewController.state
			cell.backgroundColor = state.riskTintColor
			cell.textLabel?.textColor = state.riskContrastColor
			cell.textLabel?.text = text
		}
	}

	static func riskLoading(text: String) -> DynamicCell {
		.exposureDetectionCell(ExposureDetectionViewController.ReusableCellIdentifier.riskLoading) { viewController, cell, _ in
			let state = viewController.state
			cell.backgroundColor = state.riskTintColor
			cell.textLabel?.text = text
		}
	}

	static func header(title: String, subtitle: String) -> DynamicCell {
		.exposureDetectionCell(ExposureDetectionViewController.ReusableCellIdentifier.header) { _, cell, _ in
			let cell = cell as? ExposureDetectionHeaderCell
			cell?.titleLabel?.text = title
			cell?.subtitleLabel?.text = subtitle
			cell?.titleLabel?.accessibilityTraits = .header
		}
	}

	static func guide(text: String, image: UIImage?) -> DynamicCell {
		.exposureDetectionCell(ExposureDetectionViewController.ReusableCellIdentifier.guide) { viewController, cell, _ in
			let state = viewController.state
			var tintColor = state.isTracingEnabled ? state.riskTintColor : .enaColor(for: .riskNeutral)
			if state.riskLevel == .unknownOutdated { tintColor = .enaColor(for: .riskNeutral) }
			if state.riskLevel == .inactive { tintColor = .enaColor(for: .riskNeutral) }
			cell.tintColor = tintColor
			cell.textLabel?.text = text
			cell.imageView?.image = image
		}
	}

	static func guide(image: UIImage?, text: [String]) -> DynamicCell {
		.exposureDetectionCell(ExposureDetectionViewController.ReusableCellIdentifier.longGuide) { viewController, cell, _ in
			let state = viewController.state
			cell.tintColor = state.isTracingEnabled ? state.riskTintColor : .enaColor(for: .riskNeutral)
			(cell as? ExposureDetectionLongGuideCell)?.configure(image: image, text: text)
		}
	}

	static func link(text: String, url: URL?) -> DynamicCell {
		.exposureDetectionCell(ExposureDetectionViewController.ReusableCellIdentifier.link, action: .open(url: url)) { _, cell, _ in
			cell.textLabel?.text = text
		}
	}

	static func hotline(number: String) -> DynamicCell {
		.exposureDetectionCell(ExposureDetectionViewController.ReusableCellIdentifier.hotline) { _, cell, _ in
			(cell as? InsetTableViewCell)?.insetContentView.primaryAction = {
				if let url = URL(string: "tel://\(number)") { UIApplication.shared.open(url) }
			}
		}
	}
}

// MARK: - Exposure Detection Model

extension ExposureDetectionViewController {
	private func riskSection(isHidden: @escaping (DynamicTableViewController) -> Bool, cells: [DynamicCell]) -> DynamicSection {
		.section(
			header: .none,
			footer: .riskTint(height: 16),
			isHidden: isHidden,
			cells: cells
		)
	}

	private func riskDataSection(cells: [DynamicCell]) -> DynamicSection {
		riskSection(
			isHidden: { (($0 as? Self)?.state.isLoading ?? false) },
			cells: cells
		)
	}

	private var riskLoadingSection: DynamicSection {
		.section(
			header: .none,
			footer: .none,
			isHidden: { !(($0 as? Self)?.state.isLoading ?? false) },
			cells: [
				.riskLoading(text: AppStrings.ExposureDetection.loadingText)
			]
		)
	}

	private var standardGuideSection: DynamicSection {
		let dynamicTextService = BEDynamicInformationTextService()
		let dynamicSections = dynamicTextService.sections(.standard, section: .preventiveMeasures)
		var cells: [DynamicCell] = [.header(title: AppStrings.ExposureDetection.behaviorTitle, subtitle: AppStrings.ExposureDetection.behaviorSubtitle)]
		
		cells.append(contentsOf: dynamicSections.map { $0.buildRiskLevelDynamicCell() })
			
		return .section(
			header: .backgroundSpace(height: 16),
			cells: cells
		)
	}
	
	private var highRiskGuideSection: DynamicSection {
		let dynamicTextService = BEDynamicInformationTextService()
		let dynamicSections = dynamicTextService.sections(.highRisk, section: .preventiveMeasures)

		var cells: [DynamicCell] = [.header(title: AppStrings.ExposureDetection.behaviorTitle, subtitle: AppStrings.ExposureDetection.behaviorSubtitle)]
		
		cells.append(contentsOf: dynamicSections.map { $0.buildRiskLevelDynamicCell() })
			
		return .section(
			header: .backgroundSpace(height: 16),
			cells: cells
		)
	}

	private func activeTracingSection(accessibilityIdentifier: String?) -> DynamicSection {
		let p0 = NSLocalizedString(
			"ExposureDetection_ActiveTracingSection_Text_Paragraph0",
			comment: ""
		)

		let p1 = state.risk?.details.activeTracing.exposureDetectionActiveTracingSectionTextParagraph1 ?? ""

		let body = [p0, p1].joined(separator: "\n\n")

		return .section(
			header: .backgroundSpace(height: 8),
			footer: .backgroundSpace(height: 16),
			cells: [
				.header(
					title: NSLocalizedString(
						"ExposureDetection_ActiveTracingSection_Title",
						comment: ""
					),
					subtitle: NSLocalizedString(
						"ExposureDetection_ActiveTracingSection_Subtitle",
						comment: ""
					)
				),
				.body(
					text: body,
					accessibilityIdentifier: accessibilityIdentifier
				)
			]
		)
	}

	private func explanationSection(text: String, isActive: Bool, accessibilityIdentifier: String?) -> DynamicSection {
		.section(
			header: .backgroundSpace(height: 8),
			footer: .backgroundSpace(height: 16),
			cells: [
			]
		)
	}

	private var offModel: DynamicTableViewModel {
		DynamicTableViewModel([
			.section(
				header: .none,
				footer: .separator(color: .enaColor(for: .hairline), height: 1, insets: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)),
				cells: [
					.riskText(text: AppStrings.ExposureDetection.offText),
					.riskLastRiskLevel(hasSeparator: false, text: AppStrings.ExposureDetection.lastRiskLevel, image: UIImage(named: "Icons_LetzteErmittlung-Light")),
					.riskRefreshed(text: AppStrings.ExposureDetection.refreshed, image: UIImage(named: "Icons_Aktualisiert"))
				]
			),
			riskLoadingSection,
			standardGuideSection,
			explanationSection(
				text: AppStrings.ExposureDetection.explanationTextOff, isActive: false,
				accessibilityIdentifier: AccessibilityIdentifiers.ExposureDetection.explanationTextOff)
		])
	}

	private var outdatedRiskModel: DynamicTableViewModel {
		DynamicTableViewModel([
			.section(
				header: .none,
				footer: .separator(color: .enaColor(for: .hairline), height: 1, insets: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)),
				cells: [
					.riskText(text: AppStrings.ExposureDetection.outdatedText),
					.riskLastRiskLevel(hasSeparator: false, text: AppStrings.ExposureDetection.lastRiskLevel, image: UIImage(named: "Icons_LetzteErmittlung-Light")),
					.riskRefreshed(text: AppStrings.ExposureDetection.refreshed, image: UIImage(named: "Icons_Aktualisiert"))
				]
			),
			riskLoadingSection,
			standardGuideSection,
			explanationSection(
				text: AppStrings.ExposureDetection.explanationTextOutdated,
				isActive: false,
				accessibilityIdentifier: AccessibilityIdentifiers.ExposureDetection.explanationTextOutdated
			)
		])
	}

	private var unknownRiskModel: DynamicTableViewModel {
		DynamicTableViewModel([
			riskDataSection(cells: [
				.riskText(text: AppStrings.ExposureDetection.unknownText)
			]),
			riskLoadingSection,
			standardGuideSection
		])
	}

	private var lowRiskModel: DynamicTableViewModel {
		let activeTracing = state.risk?.details.activeTracing ?? .init(interval: 0)

		return DynamicTableViewModel([
			riskDataSection(
				cells: [
				.riskContacts(text: AppStrings.ExposureDetection.numberOfContacts, image: UIImage(named: "Icons_KeineRisikoBegegnung")),
				.riskStored(activeTracing: activeTracing, imageName: "Icons_TracingCircle-Dark_Step %u"),
				.riskRefreshed(text: AppStrings.ExposureDetection.refreshed, image: UIImage(named: "Icons_Aktualisiert"))
			]),
			riskLoadingSection,
			standardGuideSection,
			activeTracingSection(accessibilityIdentifier: "hello")
		])
	}

	private var highRiskModel: DynamicTableViewModel {
		let activeTracing = state.risk?.details.activeTracing ?? .init(interval: 0)
		return DynamicTableViewModel([
			riskDataSection(cells: [
				.riskContacts(text: AppStrings.ExposureDetection.numberOfContacts, image: UIImage(named: "Icons_RisikoBegegnung")),
				.riskLastExposure(text: AppStrings.ExposureDetection.lastExposure, image: UIImage(named: "Icons_Calendar")),
				.riskStored(activeTracing: activeTracing, imageName: "Icons_TracingCircle-Dark_Step %u"),
				.riskRefreshed(text: AppStrings.ExposureDetection.refreshed, image: UIImage(named: "Icons_Aktualisiert"))
			]),
			riskLoadingSection,
			highRiskGuideSection,
			activeTracingSection(
				accessibilityIdentifier: AccessibilityIdentifiers.ExposureDetection.activeTracingSectionText
			)
		])
	}
}

extension ActiveTracing {
	var exposureDetectionActiveTracingSectionTextParagraph1: String {
		let format = NSLocalizedString("ExposureDetection_ActiveTracingSection_Text_Paragraph1", comment: "")
		return String(format: format, maximumNumberOfDays, inDays)
	}

	var exposureDetectionActiveTracingSectionTextParagraph0: String {
		return NSLocalizedString("ExposureDetection_ActiveTracingSection_Text_Paragraph0", comment: "")
	}
}
