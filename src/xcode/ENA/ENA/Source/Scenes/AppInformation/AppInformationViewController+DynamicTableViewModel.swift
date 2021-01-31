// Corona-Warn-App
//
// SAP SE and all other contributors
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

private extension DynamicCell {

	static func headlineWithoutBottomInset(text: String, accessibilityIdentifier: String?) -> Self {
		.headline(text: text, accessibilityIdentifier: accessibilityIdentifier) { _, cell, _ in
			cell.contentView.preservesSuperviewLayoutMargins = false
			cell.contentView.layoutMargins.bottom = 0
			cell.accessibilityIdentifier = accessibilityIdentifier
			cell.accessibilityTraits = .header
		}
	}

	static func bodyWithoutTopInset(text: String, style: TextCellStyle = .label, accessibilityIdentifier: String?) -> Self {
		.body(text: text, style: style, accessibilityIdentifier: accessibilityIdentifier) { _, cell, _ in
			cell.contentView.preservesSuperviewLayoutMargins = false
			cell.contentView.layoutMargins.top = 0
			cell.accessibilityIdentifier = accessibilityIdentifier
		}
	}

	/// Creates a cell that renders a view of a .html file with interactive texts, such as mail links, phone numbers, and web addresses.
	static func html(url: URL?) -> Self {
		.identifier(AppInformationDetailViewController.CellReuseIdentifier.html) { viewController, cell, _  in
			guard let cell = cell as? DynamicTableViewHtmlCell else { return }
			cell.textView.delegate = viewController as? UITextViewDelegate
			cell.textView.isUserInteractionEnabled = true
			cell.textView.dataDetectorTypes = [.link, .phoneNumber]

			if let url = url {
				cell.textView.load(from: url)
			}
		}
	}
}

private extension DynamicAction {
	static var safari: Self {
		.execute { viewController in
			LinkHelper.showWebPage(from: viewController, urlString: AppStrings.SafariView.targetURL)
		}
	}

	static func push(model: DynamicTableViewModel, separators: Bool = false, withTitle title: String) -> Self {
		.execute { viewController in
			let detailViewController = AppInformationDetailViewController()
			detailViewController.title = title
			detailViewController.dynamicTableViewModel = model
			detailViewController.separatorStyle = separators ? .singleLine : .none
			viewController.navigationController?.pushViewController(detailViewController, animated: true)
		}
	}
}

extension AppInformationViewController {
	static let model: [Category: (text: String, accessibilityIdentifier: String?, action: DynamicAction)] = [
		.about: (
			text: AppStrings.AppInformation.aboutNavigation,
			accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.aboutNavigation,
			action: .push(model: aboutModel, withTitle:  AppStrings.AppInformation.aboutNavigation)
		),
		.terms: (
			text: AppStrings.AppInformation.termsTitle,
			accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.termsNavigation,
			action: .push(model: termsModel, withTitle:  AppStrings.AppInformation.termsNavigation)
		),
		.privacy: (
			text: AppStrings.AppInformation.privacyNavigation,
			accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.privacyNavigation,
			action: .push(model: privacyModel, withTitle:  AppStrings.AppInformation.privacyNavigation)
		),
		.legal: (
			text: AppStrings.AppInformation.legalNavigation,
			accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.legalNavigation,
			action: .push(model: legalModel, separators: true, withTitle:  AppStrings.AppInformation.legalNavigation)
		),
		.imprint: (
			text: AppStrings.AppInformation.imprintNavigation,
			accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.imprintNavigation,
			action: .push(model: imprintModel, withTitle:  AppStrings.AppInformation.imprintNavigation)
		)
	]
}

extension AppInformationViewController {
	private static let aboutModel = DynamicTableViewModel([
		.section(
			header: .image(UIImage(named: "Illu_AppInfo_UeberApp"),
						   accessibilityLabel: AppStrings.AppInformation.aboutImageDescription,
						   accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.aboutImageDescription,
						   height: 230),
			cells: [
				.title2(text: AppStrings.AppInformation.aboutTitle,
						accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.aboutTitle),
				.headline(text: AppStrings.AppInformation.aboutDescription,
						  accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.aboutDescription),
				.subheadline(text: AppStrings.AppInformation.aboutText,
							 accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.aboutText)
			]
		)
	])

	private static let imprintModel = DynamicTableViewModel([
		.section(
			header: .image(UIImage(named: "Illu_Appinfo_Impressum"),
						   accessibilityLabel: AppStrings.AppInformation.imprintImageDescription,
						   accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.imprintImageDescription,
						   height: 230),
			cells: [
				.headlineWithoutBottomInset(text: AppStrings.AppInformation.imprintSection2Title,
											accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.imprintSection2Title),
				.bodyWithoutTopInset(text: AppStrings.AppInformation.imprintSection2Text,
									 style: .textView([]),
									 accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.imprintSection2Text),
				.headlineWithoutBottomInset(text: AppStrings.AppInformation.imprintSection3Title,
											accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.imprintSection3Title),
				.bodyWithoutTopInset(text: AppStrings.AppInformation.imprintSection3Text,
									 style: .textView(.all),
									 accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.imprintSection3Text),
				.headlineWithoutBottomInset(text: AppStrings.AppInformation.imprintSection4Title,
											accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.imprintSection4Title),
				.bodyWithoutTopInset(text: AppStrings.AppInformation.imprintSection4Text,
									 style: .textView([]),
									 accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.imprintSection4Text)
			]
		)
	])

	private static let privacyModel = DynamicTableViewModel([
		.section(
			header: .image(
				UIImage(named: "Illu_Appinfo_Datenschutz"),
				accessibilityLabel: AppStrings.AppInformation.privacyImageDescription,
				accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.privacyImageDescription,
				height: 230
			),
			cells: [
				.title2(
					text: AppStrings.AppInformation.privacyTitle,
					accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.privacyTitle),
				.html(url: Bundle.main.url(forResource: "privacy-policy", withExtension: "html"))
			]
		)
	])

	private static let termsModel = DynamicTableViewModel([
		.section(
			header: .image(UIImage(named: "Illu_Appinfo_Nutzungsbedingungen"),
						   accessibilityLabel: AppStrings.AppInformation.termsImageDescription,
						   accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.termsImageDescription,
						   height: 230),
			cells: [
				.title2(
					text: AppStrings.AppInformation.termsTitle,
					accessibilityIdentifier: AccessibilityIdentifiers.AppInformation.termsTitle),
				.html(url: Bundle.main.url(forResource: "usage", withExtension: "html"))
			]
		)
	])
}
