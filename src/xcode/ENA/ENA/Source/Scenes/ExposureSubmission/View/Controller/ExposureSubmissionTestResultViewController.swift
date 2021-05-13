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

class ExposureSubmissionTestResultViewController: DynamicTableViewController, ENANavigationControllerWithFooterChild {

	// MARK: - Attributes.

	var testResult: TestResult?
	var timeStamp: Int64?
	
	private(set) weak var coordinator: ExposureSubmissionFromTestCoordinating?
	private(set) weak var exposureSubmissionService: BEExposureSubmissionService?

	private var footerItem = ENANavigationFooterItem()
	
	override var navigationItem: UINavigationItem {
		footerItem
	}

	// MARK: - Initializers.

	init(coordinator: ExposureSubmissionFromTestCoordinating, exposureSubmissionService: BEExposureSubmissionService, testResult: TestResult?) {
		self.coordinator = coordinator
		self.exposureSubmissionService = exposureSubmissionService
		self.testResult = testResult
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View Lifecycle methods.

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupButtons()
	}
	

	override func viewDidLoad() {
		super.viewDidLoad()
		cellBackgroundColor = .clear
		view.backgroundColor = .enaColor(for: .background)
		tableView.separatorStyle = .none
		
		setupView()
	}

	// MARK: - View Setup Helper methods.

	private func setupView() {
		setupDynamicTableView()
		setupNavigationBar()
		timeStamp = exposureSubmissionService?.devicePairingSuccessfulTimestamp
		if let testResult = testResult {
			if testResult.result == .positive {
				
				// make sure we have to push the button at the bottom to get out of this screen
				if #available(iOS 13.0, *) {
					self.isModalInPresentation = true
				}
				
				navigationController?.navigationItem.rightBarButtonItem = nil
			}
		}
	}

	private func setupButtons() {
		// :BE: change enum to struct
		guard let testResult = testResult else { return }
		let result = testResult.result
		// :BE: - end

		// Make sure to reset all button loading states.
		self.navigationFooterItem?.isPrimaryButtonLoading = false
		self.navigationFooterItem?.isSecondaryButtonLoading = false

		// Make sure to reset buttons to default state.
		self.navigationFooterItem?.isPrimaryButtonEnabled = true
		self.navigationFooterItem?.isPrimaryButtonHidden = false

		self.navigationFooterItem?.isSecondaryButtonEnabled = false
		self.navigationFooterItem?.isSecondaryButtonHidden = true

		// :BE: add accessibility identifier
		self.footerView?.primaryButton?.accessibilityIdentifier = BEAccessibilityIdentifiers.BETestResult.next
		
		switch result {
		case .positive:
			navigationFooterItem?.primaryButtonTitle = AppStrings.ExposureSubmissionResult.continueButton
			navigationFooterItem?.isSecondaryButtonHidden = true
			// make sure we have to push the button at the bottom to get out of this screen
			navigationItem.rightBarButtonItem = nil
		case .negative, .invalid:
			navigationFooterItem?.primaryButtonTitle = AppStrings.ExposureSubmissionResult.deleteButton
			navigationFooterItem?.isSecondaryButtonHidden = true
		case .pending:
			navigationFooterItem?.primaryButtonTitle = AppStrings.ExposureSubmissionResult.refreshButton
			navigationFooterItem?.secondaryButtonTitle = AppStrings.ExposureSubmissionResult.deleteButton
			navigationFooterItem?.isSecondaryButtonEnabled = true
			navigationFooterItem?.isSecondaryButtonHidden = false
		}
	}

	private func setupNavigationBar() {
		navigationItem.hidesBackButton = true
		navigationController?.navigationItem.largeTitleDisplayMode = .always
		navigationItem.title = AppStrings.ExposureSubmissionResult.title
	}

	private func setupDynamicTableView() {
		guard let result = testResult else {
			logError(message: "No test result.", level: .error)
			return
		}

		tableView.register(
			UINib(nibName: String(describing: ExposureSubmissionTestResultHeaderView.self), bundle: nil),
			forHeaderFooterViewReuseIdentifier: HeaderReuseIdentifier.testResult.rawValue
		)
		tableView.register(
			UINib(nibName: String(describing: ExposureSubmissionStepCell.self), bundle: nil),
			forCellReuseIdentifier: CustomCellReuseIdentifiers.stepCell.rawValue
		)

		dynamicTableViewModel = dynamicTableViewModel(for: result)
	}

	// MARK: - Convenience methods for buttons.

	private func deleteTest() {
		let alert = UIAlertController(
			title: AppStrings.ExposureSubmissionResult.removeAlert_Title,
			message: AppStrings.ExposureSubmissionResult.removeAlert_Text,
			preferredStyle: .alert
		)

		let cancel = UIAlertAction(
			title: AppStrings.Common.alertActionCancel,
			style: .cancel,
			handler: { _ in alert.dismiss(animated: true, completion: nil) }
		)

		let delete = UIAlertAction(
			title: AppStrings.Common.alertActionRemove,
			style: .destructive,
			handler: { _ in
				self.exposureSubmissionService?.deleteTest()
				self.navigationController?.dismiss(animated: true, completion: nil)
			}
		)

		alert.addAction(delete)
		alert.addAction(cancel)

		present(alert, animated: true, completion: nil)
	}

	private func refreshTest() {
		navigationFooterItem?.isPrimaryButtonEnabled = false
		navigationFooterItem?.isPrimaryButtonLoading = true
		exposureSubmissionService?
			.getTestResult { result in
				switch result {
				case let .failure(error):

					let alert = Self.setupErrorAlert(message: error.localizedDescription)
					
					self.present(alert, animated: true, completion: {
						self.navigationFooterItem?.isPrimaryButtonEnabled = true
						self.navigationFooterItem?.isPrimaryButtonLoading = false
					})
				case let .success(testResult):
					self.refreshView(for: testResult)
				}
			}
	}

	private func refreshView(for result: TestResult) {
		exposureSubmissionService?.setTestResultShownOnScreen()
		self.testResult = result
		self.dynamicTableViewModel = self.dynamicTableViewModel(for: result)
		self.tableView.reloadData()
		self.setupButtons()
	}

	/// Only show the "warn others" screen if the ENManager is enabled correctly,
	/// otherwise, show an alert.
	private func showWarnOthers() {
		if let state = exposureSubmissionService?.preconditions() {
			if !state.isGood {

				let alert = Self.setupErrorAlert(
					message: ExposureSubmissionError.enNotEnabled.localizedDescription
				)
				self.present(alert, animated: true, completion: nil)
				return
			}

			self.coordinator?.showWarnOthersScreen()
		}
	}
}

// MARK: - Custom HeaderReuseIdentifiers.

extension ExposureSubmissionTestResultViewController {
	enum HeaderReuseIdentifier: String, TableViewHeaderFooterReuseIdentifiers {
		case testResult = "testResultCell"
	}
}

// MARK: - Cell reuse identifiers.

extension ExposureSubmissionTestResultViewController {
	enum CustomCellReuseIdentifiers: String, TableViewCellReuseIdentifiers {
		case stepCell
	}
}

// MARK: ENANavigationControllerWithFooterChild methods.

extension ExposureSubmissionTestResultViewController {
	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		// :BE: change enum to struct
		guard let testResult = testResult else { return }
		let result = testResult.result
		// :BE: - end

		switch result {
		case .positive:
			showWarnOthers()
		case .negative, .invalid:
			deleteTest()
		case .pending:
			refreshTest()
		}
	}

	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapSecondaryButton button: UIButton) {
		// :BE: change enum to struct
		guard let testResult = testResult else { return }
		let result = testResult.result
		// :BE: - end

		switch result {
		case .pending:
			deleteTest()
		default:
			// Secondary button is only active for pending result state.
			break
		}
	}
}

// MARK: - DynamicTableViewModel convenience setup methods.

private extension ExposureSubmissionTestResultViewController {
	
	// :BE: change enum to struct
	private func dynamicTableViewModel(for testResult: TestResult) -> DynamicTableViewModel {
		DynamicTableViewModel.with {
			$0.add(
				testResultSection(for: testResult.result)
			)
		}
	}

	// :BE: change enum
	private func testResultSection(for result: TestResult.Result) -> DynamicSection {
		switch result {
		case .positive:
			return positiveTestResultSection()
		case .negative:
			return negativeTestResultSection()
		case .invalid:
			return invalidTestResultSection()
		case .pending:
			return pendingTestResultSection()
		}
	}

	private func positiveTestResultSection() -> DynamicSection {
		let dynamicTextService = BEDynamicInformationTextService()
		let textSections = dynamicTextService.sections(.positiveTestResult, section: .explanation)
		let tintColor = UIColor.enaColor(for: .riskHigh)
		let stepCells = Array(textSections.map({ $0.buildTestResultStepCells(iconTint: tintColor) }).joined())

		var cells: [DynamicCell] = [.title2(text: AppStrings.ExposureSubmissionResult.procedure,
					accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionResult.procedure)]

		cells.append(contentsOf: stepCells)

		return .section(
			header: .identifier(
				ExposureSubmissionTestResultViewController.HeaderReuseIdentifier.testResult,
				configure: { view, _ in
					(view as? ExposureSubmissionTestResultHeaderView)?.configure(testResult: .positive, timeStamp: self.timeStamp)
				}
			),
			separators: false,
			cells: cells
		)
	}

	private func negativeTestResultSection() -> DynamicSection {
		let dynamicTextService = BEDynamicInformationTextService()
		let textSections = dynamicTextService.sections(.negativeTestResult, section: .explanation)
		let tintColor = UIColor.enaColor(for: .riskLow)
		let stepCells = Array(textSections.map({ $0.buildTestResultStepCells(iconTint: tintColor) }).joined())

		var cells: [DynamicCell] = [.title2(text: AppStrings.ExposureSubmissionResult.procedure,
					accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionResult.procedure)]
		
		cells.append(contentsOf: stepCells)

		cells.append(contentsOf: [
			.title2(text: AppStrings.ExposureSubmissionResult.furtherInfos_Title,
					accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionResult.furtherInfos_Title),
			ExposureSubmissionDynamicCell.stepCell(bulletPoint: AppStrings.ExposureSubmissionResult.furtherInfos_ListItem1),
			ExposureSubmissionDynamicCell.stepCell(bulletPoint: AppStrings.ExposureSubmissionResult.furtherInfos_ListItem2),
			ExposureSubmissionDynamicCell.stepCell(bulletPoint: AppStrings.ExposureSubmissionResult.furtherInfos_ListItem3),
			ExposureSubmissionDynamicCell.stepCell(bulletPoint: AppStrings.ExposureSubmissionResult.furtherInfos_TestAgain)
		])
		
		return .section(
			header: .identifier(
				ExposureSubmissionTestResultViewController.HeaderReuseIdentifier.testResult,
				configure: { view, _ in
					(view as? ExposureSubmissionTestResultHeaderView)?.configure(testResult: .negative, timeStamp: self.timeStamp)
				}
			),
			separators: false,
			cells: cells
		)
	}

	private func invalidTestResultSection() -> DynamicSection {
		.section(
			header: .identifier(
				ExposureSubmissionTestResultViewController.HeaderReuseIdentifier.testResult,
				configure: { view, _ in
					(view as? ExposureSubmissionTestResultHeaderView)?.configure(testResult: .invalid, timeStamp: self.timeStamp)
				}
			),
			separators: false,
			cells: [
				.title2(text: AppStrings.ExposureSubmissionResult.procedure,
						accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionResult.procedure),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testAdded,
					description: AppStrings.ExposureSubmissionResult.testAddedDesc,
					icon: UIImage(named: "Icons_Grey_Check"),
					hairline: .iconAttached
				),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testInvalid,
					description: AppStrings.ExposureSubmissionResult.testInvalidDesc,
					icon: UIImage(named: "Icons_Grey_Error"),
					hairline: .topAttached
				),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testRemove,
					description: AppStrings.ExposureSubmissionResult.testRemoveDesc,
					icon: UIImage(named: "Icons_Grey_Entfernen"),
					hairline: .none
				)
			]
		)
	}

	private func pendingTestResultSection() -> DynamicSection {
		.section(
			header: .identifier(
				ExposureSubmissionTestResultViewController.HeaderReuseIdentifier.testResult,
				configure: { view, _ in
					(view as? ExposureSubmissionTestResultHeaderView)?.configure(testResult: .pending, timeStamp: self.timeStamp)
				}
			),
			cells: [
				.title2(text: AppStrings.ExposureSubmissionResult.procedure,
						accessibilityIdentifier: AccessibilityIdentifiers.ExposureSubmissionResult.procedure),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testAdded,
					description: exposureSubmissionService?.mobileTestId?.descriptionForPendingTestResult, // :BE: longer description
					icon: UIImage(named: "Icons_Grey_Check"),
					hairline: .iconAttached
				),

				ExposureSubmissionDynamicCell.stepCell(
					title: AppStrings.ExposureSubmissionResult.testPending,
					description: AppStrings.ExposureSubmissionResult.testPendingDesc,
					icon: UIImage(named: "Icons_Grey_Wait"),
					hairline: .none
				)
			]
		)
	}
}

// :BE: longer description
extension BEMobileTestId {
	fileprivate var descriptionForPendingTestResult: String {
		var descriptionText = AppStrings.ExposureSubmissionResult.testAddedDesc
		guard let dateWithoutTime = self.datePatientInfectious.dateWithoutTime else {
			fatalError("Wrong date format")
		}
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none

		descriptionText += "\n\n"
		descriptionText += BEAppStrings.BEMobileTestId.dateInfectious
		descriptionText += "\n"
		descriptionText += dateFormatter.string(from: dateWithoutTime)
		descriptionText += "\n\n"
		descriptionText += BEAppStrings.BEMobileTestId.code
		descriptionText += "\n"
		descriptionText += self.fullString
		descriptionText += "\n"

		return descriptionText
	}
}
