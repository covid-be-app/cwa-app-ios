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
import UIKit

class BEExposureSubmissionCoordinator : ExposureSubmissionCoordinating {

	
	// MARK: - Attributes.

	/// - NOTE: The delegate is called by the `viewWillDisappear(_:)` method of the `navigationController`.
	weak var delegate: ExposureSubmissionCoordinatorDelegate?
	weak var parentNavigationController: UINavigationController?

	weak var navigationController: UINavigationController?

	/// - NOTE: We need a strong (aka non-weak) reference here.
	let exposureSubmissionService: ExposureSubmissionService

	// MARK: - Initializers.

	init(
		parentNavigationController: UINavigationController,
		exposureSubmissionService: ExposureSubmissionService,
		delegate: ExposureSubmissionCoordinatorDelegate? = nil
	) {
		self.parentNavigationController = parentNavigationController
		self.exposureSubmissionService = exposureSubmissionService
		self.delegate = delegate
	}

	// MARK: - ExposureSubmissionCoordinating

	/// Starts the coordinator and displays the initial root view controller.
	/// The underlying implementation may decide which initial screen to show, currently the following options are possible:
	/// - Case 1: When a valid test result is provided, the coordinator shows the test result screen.
	/// - Case 2: (DEFAULT) The coordinator shows the intro screen.
	/// - Case 3: (UI-Testing) The coordinator may be configured to show other screens for UI-Testing.

	func start(with result: TestResult?) {
		let initialVC = getInitialViewController(with: result)
		guard let parentNavigationController = parentNavigationController else {
			log(message: "Parent navigation controller not set.", level: .error, file: #file, line: #line, function: #function)
			return
		}

		/// The navigation controller keeps a strong reference to the coordinator. The coordinator only reaches reference count 0
		/// when UIKit dismisses the navigationController.
		let navigationController = createNavigationController(rootViewController: initialVC)
		parentNavigationController.present(navigationController, animated: true)
		self.navigationController = navigationController
	}

	func dismiss() {
		navigationController?.dismiss(animated: true)
	}


	// We will "abuse" this name to show the QR code screen without having to modify the entire structure of the calls
	// This is what is called after showing the intro screen
	// In the original app it will show you the 3 possibilities to register a test, in our case we go directly to the code generator
	
	func showOverviewScreen() {
		
		let alert = UIAlertController(
			title: AppStrings.ExposureSubmission.dataPrivacyTitle,
			message: AppStrings.ExposureSubmission.dataPrivacyDisclaimer,
			preferredStyle: .alert
		)
		let acceptAction = UIAlertAction(title: AppStrings.ExposureSubmission.dataPrivacyAcceptTitle,
										 style: .default, handler: { _ in
											let vc = self.createMobileTestIdController()
											self.push(vc)
											self.exposureSubmissionService.acceptPairing()
		})
		alert.addAction(acceptAction)

		alert.addAction(.init(title: AppStrings.ExposureSubmission.dataPrivacyDontAcceptTitle,
							  style: .cancel,
							  handler: { _ in
								alert.dismiss(animated: true, completion: nil) }
			))
		
		alert.preferredAction = acceptAction
		present(alert)
	}

	// MARK: - Methods no longer used

	func showHotlineScreen() {
		fatalError()
	}
	
	func showTanScreen() {
		fatalError()
	}

	func showQRScreen(qrScannerDelegate: ExposureSubmissionQRScannerDelegate) {
		fatalError()
	}

	func showTestResultScreen(with result: TestResult) {
		fatalError()
	}

	func showWarnOthersScreen() {
		fatalError()
	}

	func showThankYouScreen() {
		fatalError()
	}
	

	// MARK: - Helpers.
	
	private func push(_ vc: UIViewController) {
		self.navigationController?.pushViewController(vc, animated: true)
	}

	private func present(_ vc: UIViewController) {
		self.navigationController?.present(vc, animated: true)
	}
	
	private func createMobileTestIdController() -> BEMobileTestIdViewController {
		let vc = BEMobileTestIdViewController()
		vc.delegate = self
		
		return vc
	}

	private func createNavigationController(rootViewController vc:UIViewController)  -> ExposureSubmissionNavigationController {
		return AppStoryboard.exposureSubmission.initiateInitial { coder in
			return ExposureSubmissionNavigationController(coder: coder, coordinator: self, rootViewController: vc)
		}
	}
	
	private func getInitialViewController(with result: TestResult? = nil) -> UIViewController {
		#if UITESTING
		if ProcessInfo.processInfo.arguments.contains("-negativeResult") {
			return createTestResultViewController(with: .negative)
		}

		#else
		// We got a test result and can jump straight into the test result view controller.
		if let result = result, exposureSubmissionService.hasRegistrationToken() {
			return createTestResultViewController(with: result)
		}
		#endif

		// By default, we show the intro view.
		return createIntroViewController()
	}

	private func createTestResultViewController(with result: TestResult) -> ExposureSubmissionTestResultViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionTestResultViewController.self) { coder -> UIViewController? in
			ExposureSubmissionTestResultViewController(
				coder: coder,
				coordinator: self,
				exposureSubmissionService: self.exposureSubmissionService,
				testResult: result
			)
		}
	}
	
	private func createIntroViewController() -> ExposureSubmissionIntroViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionIntroViewController.self) { coder -> UIViewController? in
			ExposureSubmissionIntroViewController(coder: coder, coordinator: self)
		}
	}
	
	private func createWarnOthersViewController() -> ExposureSubmissionWarnOthersViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionWarnOthersViewController.self) { coder -> UIViewController? in
			ExposureSubmissionWarnOthersViewController(coder: coder, coordinator: self, exposureSubmissionService: self.exposureSubmissionService)
		}
	}

	private func createSuccessViewController() -> ExposureSubmissionSuccessViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionSuccessViewController.self) { coder -> UIViewController? in
			ExposureSubmissionSuccessViewController(coder: coder, coordinator: self)
		}
	}
}

extension BEExposureSubmissionCoordinator : BEMobileTestIdViewControllerDelegate {
	
	func mobileTestIdViewController(_ vc: BEMobileTestIdViewController, finshedWithMobileTestId mobileTestId: BeMobileTestId) {
		(exposureSubmissionService as! ENAExposureSubmissionService).addMobileTestId(mobileTestId)
		self.navigationController?.dismiss(animated: true)
	}
	
}
