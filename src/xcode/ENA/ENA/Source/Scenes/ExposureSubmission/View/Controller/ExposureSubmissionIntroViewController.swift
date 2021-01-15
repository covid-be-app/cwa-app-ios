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

import UIKit

class ExposureSubmissionIntroViewController: DynamicTableViewController, ENANavigationControllerWithFooterChild {

	// MARK: - Attributes.

	private(set) weak var coordinator: ExposureSubmissionCoordinating?

	// MARK: - Initializers.

	init(coordinator: ExposureSubmissionCoordinating) {
		self.coordinator = coordinator
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private lazy var navigationFooterItem: ENANavigationFooterItem = {
		let item = ENANavigationFooterItem()

		item.isPrimaryButtonHidden = false
		item.isPrimaryButtonEnabled = true
		item.isSecondaryButtonHidden = true

		item.title = AppStrings.ExposureSubmissionIntroduction.title
		item.largeTitleDisplayMode = .automatic

		item.primaryButtonTitle = AppStrings.ExposureSubmission.continueText

		return item
	}()
	
	override var navigationItem: UINavigationItem {
		navigationFooterItem
	}

	override func viewDidLoad() {
		super.viewDidLoad()


		setupView()
		setupBackButton()

		footerView?.primaryButton?.accessibilityIdentifier = AccessibilityIdentifiers.ExposureSubmission.continueText
	}

	// MARK: - Setup helpers.

	private func setupView() {
		view.backgroundColor = .enaColor(for: .background)
		hidesBottomBarWhenPushed = true

		tableView.register(UINib(nibName: String(describing: ExposureSubmissionStepCell.self), bundle: nil), forCellReuseIdentifier: CustomCellReuseIdentifiers.stepCell.rawValue)
		dynamicTableViewModel = .intro
		tableView.separatorStyle = .none
	}

	// MARK: - ENANavigationControllerWithFooterChild methods.

	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		coordinator?.showOverviewScreen()
	}
}

private extension DynamicTableViewModel {

	static let intro = DynamicTableViewModel([
		.section(
			header: .image(
				UIImage(named: "Illu_Submission_Funktion1"),
				accessibilityLabel: AppStrings.ExposureSubmissionIntroduction.accImageDescription,
				accessibilityIdentifier: AccessibilityIdentifiers.General.image,
				height: 200
			),
			separators: false,
			cells: [
				.body(text: AppStrings.ExposureSubmissionIntroduction.usage02,
					  accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionIntroduction.usage02),
				ExposureSubmissionDynamicCell.stepCell(bulletPoint: AppStrings.ExposureSubmissionIntroduction.listItem1),
				ExposureSubmissionDynamicCell.stepCell(bulletPoint: AppStrings.ExposureSubmissionIntroduction.listItem2)
			]
		)
	])
}

private extension ExposureSubmissionIntroViewController {
	enum CustomCellReuseIdentifiers: String, TableViewCellReuseIdentifiers {
		case stepCell
	}
}
