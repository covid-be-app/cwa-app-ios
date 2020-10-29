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

final class ExposureSubmissionSuccessViewController: DynamicTableViewController, ENANavigationControllerWithFooterChild {

	// MARK: - Attributes.

	private(set) weak var coordinator: ExposureSubmissionCoordinating?

	// MARK: - Initializers.

	init?(coder: NSCoder, coordinator: ExposureSubmissionCoordinating) {
		self.coordinator = coordinator
		super.init(coder: coder)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UIViewController.

	override func viewDidLoad() {
		super.viewDidLoad()
		setupTitle()
		setUpView()

		navigationFooterItem?.primaryButtonTitle = AppStrings.ExposureSubmissionSuccess.button
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		footerView?.primaryButton.accessibilityIdentifier = BEAccessibilityIdentifiers.BEExposureSubmissionSuccess.button
	}

	private func setUpView() {
		navigationItem.hidesBackButton = true
		tableView.register(UINib(nibName: String(describing: ExposureSubmissionStepCell.self), bundle: nil), forCellReuseIdentifier: CustomCellReuseIdentifiers.stepCell.rawValue)
		dynamicTableViewModel = .thankYouData
	}

	private func setupTitle() {
		title = AppStrings.ExposureSubmissionSuccess.title
		navigationItem.largeTitleDisplayMode = .always
		navigationController?.navigationBar.prefersLargeTitles = true
	}
}

extension ExposureSubmissionSuccessViewController {
	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		let alertController = self.setupErrorAlert(title: BEAppStrings.BEAppResetAfterTEKUpload.title, message: BEAppStrings.BEAppResetAfterTEKUpload.description, okTitle: nil, secondaryActionTitle: nil, completion: {
			self.coordinator?.resetApp()
		}, secondaryActionCompletion: nil)
		
		present(alertController, animated: true)
	}
	
}

private extension DynamicTableViewModel {
	static var thankYouData: DynamicTableViewModel {
		let dynamicTextService = BEDynamicTextService()
		let pleaseNoteSections = dynamicTextService.sections(.thankYou, section: .pleaseNote)
		let otherInformationSections = dynamicTextService.sections(.thankYou, section: .otherInformation)

		let pleaseNoteCells = Array(pleaseNoteSections.map({ $0.buildSuccessViewControllerStepCells(iconTint: .enaColor(for: .riskHigh)) }).joined())
		let otherInformationCells = Array(otherInformationSections.map({ $0.buildSuccessViewControllerStepCells(iconTint: .enaColor(for: .riskHigh)) }).joined())

		var cells: [DynamicCell] = [
			.body(text: AppStrings.ExposureSubmissionSuccess.description,
				  accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionSuccess.description),
			.title2(text: AppStrings.ExposureSubmissionSuccess.listTitle,
					accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionSuccess.listTitle)
		]
		
		cells.append(contentsOf: pleaseNoteCells)
		cells.append(
			.title2(text: AppStrings.ExposureSubmissionSuccess.subTitle,
					accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionSuccess.subTitle)
		)
		cells.append(contentsOf: otherInformationCells)

		
		return DynamicTableViewModel([
			DynamicSection.section(
				header: .image(
					UIImage(named: "Illu_Submission_VielenDank"),
					accessibilityLabel: AppStrings.ExposureSubmissionSuccess.accImageDescription,
					accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionSuccess.accImageDescription
				),
				separators: false,
				cells: cells

			)
		])
	}

}

// MARK: - Cell reuse identifiers.

extension ExposureSubmissionSuccessViewController {
	enum CustomCellReuseIdentifiers: String, TableViewCellReuseIdentifiers {
		case stepCell
	}
}
