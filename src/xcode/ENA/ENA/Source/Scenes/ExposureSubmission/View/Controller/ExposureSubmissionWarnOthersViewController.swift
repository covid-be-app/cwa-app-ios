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

class ExposureSubmissionWarnOthersViewController: DynamicTableViewController, ENANavigationControllerWithFooterChild {
	
	// MARK: - Attributes.

 	private(set) weak var exposureSubmissionService: BEExposureSubmissionService?
	private(set) weak var coordinator: ExposureSubmissionCoordinating?

	// MARK: - Initializers.

	init(coordinator: ExposureSubmissionCoordinating, exposureSubmissionService: BEExposureSubmissionService) {
		self.coordinator = coordinator
		self.exposureSubmissionService = exposureSubmissionService
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private var footerItem = ENANavigationFooterItem()
	
	override var navigationItem: UINavigationItem {
		footerItem
	}

	// MARK: - View lifecycle methods.

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .enaColor(for: .background)

		navigationItem.largeTitleDisplayMode = .always
		setupView()
		tableView.separatorStyle = .none
	}
	
	// :BE: add acc. identifier to next button
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.footerView?.primaryButton.accessibilityIdentifier = BEAccessibilityIdentifiers.BEWarnOthers.next
	}

	// MARK: Setup helpers.

	private func setupView() {
		navigationItem.title = AppStrings.ExposureSubmissionWarnOthers.title
		
		// :BE: accessibility
		navigationItem.accessibilityLabel = AppStrings.ExposureSubmissionWarnOthers.title
		navigationFooterItem?.primaryButtonTitle = AppStrings.ExposureSubmissionWarnOthers.continueButton
		navigationFooterItem?.isPrimaryButtonEnabled = true
		navigationFooterItem?.isPrimaryButtonHidden = false
		navigationFooterItem?.isSecondaryButtonHidden = true
		footerView?.isHidden = false
		setupTableView()
	}

	private func setupTableView() {
		tableView.delegate = self
		tableView.dataSource = self
		tableView.register(
			DynamicTableViewRoundedCell.self,
			forCellReuseIdentifier: CustomCellReuseIdentifiers.roundedCell.rawValue
		)
		dynamicTableViewModel = dynamicTableViewModel()
	}

	// MARK: - ExposureSubmissionService Helpers.

	internal func startSubmitProcess() {
		fatalError("Overridden")
	}

	// MARK: - UI-related helpers.


	/// Instantiates and shows an alert with a "More Info" button for
	/// the EN errors. Assumes that the passed in `error` is either of type
	/// `.internal`, `.unsupported` or `.rateLimited`.
	func showENErrorAlert(_ error: ExposureSubmissionError) {
		logError(message: "error: \(error.localizedDescription)", level: .error)
		let alert = createENAlert(error)

		self.present(alert, animated: true, completion: {
			self.navigationFooterItem?.isPrimaryButtonLoading = false
			self.navigationFooterItem?.isPrimaryButtonEnabled = true
		})
	}

	/// Creates an error alert for the EN errors.
	func createENAlert(_ error: ExposureSubmissionError) -> UIAlertController {
		return Self.setupErrorAlert(
			message: error.localizedDescription
		)
	}
}

// MARK: ENANavigationControllerWithFooterChild methods.

extension ExposureSubmissionWarnOthersViewController {
	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		navigationFooterItem?.isPrimaryButtonEnabled = false
		startSubmitProcess()
	}
}

// MARK: - DynamicTableViewModel convenience setup methods.

private extension ExposureSubmissionWarnOthersViewController {
	private func dynamicTableViewModel() -> DynamicTableViewModel {
		DynamicTableViewModel.with {
			$0.add(
				.section(
					header: .image(
						UIImage(named: "Illu_Submission_AndereWarnen"),
						accessibilityLabel: AppStrings.ExposureSubmissionWarnOthers.accImageDescription,
						accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionWarnOthers.accImageDescription,
						height: 250),
					cells: [
						.title2(text: AppStrings.ExposureSubmissionWarnOthers.sectionTitle,
								accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionWarnOthers.sectionTitle),
						.body(text: AppStrings.ExposureSubmissionWarnOthers.description,
							  accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionWarnOthers.description),
						.custom(withIdentifier: CustomCellReuseIdentifiers.roundedCell,
								configure: { _, cell, _ in
									guard let cell = cell as? DynamicTableViewRoundedCell else { return }
									cell.configure(
										title: NSMutableAttributedString(
											string: AppStrings.ExposureSubmissionWarnOthers.dataPrivacyTitle
										),
										body: NSMutableAttributedString(
											string: AppStrings.ExposureSubmissionWarnOthers.dataPrivacyDescription
										)
									)
						})
					]
				)
			)
		}
	}
}

// MARK: - Cell reuse identifiers.

extension ExposureSubmissionWarnOthersViewController {
	enum CustomCellReuseIdentifiers: String, TableViewCellReuseIdentifiers {
		case roundedCell
	}
}
