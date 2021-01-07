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
import ExposureNotification

class BEExposureSubmissionCoordinator : NSObject, ExposureSubmissionCoordinating {

	
	// MARK: - Attributes.

	/// - NOTE: The delegate is called by the `viewWillDisappear(_:)` method of the `navigationController`.
	weak var delegate: ExposureSubmissionCoordinatorDelegate?
	weak var parentNavigationController: UINavigationController?

	weak var navigationController: UINavigationController?

	/// - NOTE: We need a strong (aka non-weak) reference here.
	let exposureSubmissionService: BEExposureSubmissionService

	private var mobileTestIdGenerator: BEMobileTestIdGenerator?
	// MARK: - Initializers.

	init(
		parentNavigationController: UINavigationController,
		exposureSubmissionService: ExposureSubmissionService,
		delegate: ExposureSubmissionCoordinatorDelegate? = nil
	) {
		self.parentNavigationController = parentNavigationController
		
		guard let beSubmissionService = exposureSubmissionService as? BEExposureSubmissionService else {
			fatalError("Wrong exposure submission class")
		}
		
		self.exposureSubmissionService = beSubmissionService
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
		navigationController.delegate = self
		parentNavigationController.present(navigationController, animated: true)
		self.navigationController = navigationController
	}

	func dismiss() {
		navigationController?.dismiss(animated: true)
	}
	
	func resetApp() {
		navigationController?.dismiss(animated: true) {
			self.delegate?.exposureSubmissionCoordinatorRequestsAppReset()
		}
	}

	// We will "abuse" this name to show the test code screen without having to modify the entire structure of the calls
	// This is what is called after showing the intro screen
	// In the original app it will show you the 3 possibilities to register a test, in our case we go directly to the code generator
	
	func showOverviewScreen() {
		if let navController = navigationController {
			self.mobileTestIdGenerator = BEMobileTestIdGenerator(exposureSubmissionService: exposureSubmissionService, parentViewController: navController, delegate: self)
			self.mobileTestIdGenerator?.generate()
		}
	}

	func showWarnOthersScreen() {
		let vc = createWarnOthersViewController()
		push(vc)
	}

	func showThankYouScreen() {
		let vc = createSuccessViewController()
		push(vc)
	}
	
	func submitExposureKeys(_ exposureKeys:[ENTemporaryExposureKey]) {
		exposureSubmissionService.submitExposure(keys: exposureKeys) { error in
			if let error = error {
				logError(message: "error: \(error.localizedDescription)", level: .error)
				let alert = UIViewController.setupErrorAlert(message: error.localizedDescription)
				self.navigationController?.present(alert, animated: true)
			} else {
				self.showThankYouScreen()
			}
		}
	}

	// MARK: - Methods no longer used


	func showHotlineScreen() {
		fatalError("Deprecated")
	}
	
	func showTanScreen() {
		fatalError("Deprecated")
	}

	func showTestResultScreen(with result: TestResult) {
		fatalError("Deprecated")
	}
	
	// MARK: - Mobile test id
	
	func showMobileTestIdViewController() {
		
		guard let mobileTestId = exposureSubmissionService.mobileTestId else {
			fatalError("Missing mobile test id")
		}
		
		let vc = BEMobileTestIdViewController(mobileTestId)
		vc.delegate = self

		self.push(vc)
	}

	// MARK: - Helpers.
	
	private func push(_ vc: UIViewController) {
		self.navigationController?.pushViewController(vc, animated: true)
	}

	private func present(_ vc: UIViewController) {
		self.navigationController?.present(vc, animated: true)
	}
	
	private func createNavigationController(rootViewController vc:UIViewController)  -> ExposureSubmissionNavigationController {
		return ExposureSubmissionNavigationController(coordinator: self, rootViewController: vc)
	}
	
	private func getInitialViewController(with result: TestResult? = nil) -> UIViewController {
		// We got a test result and can jump straight into the test result view controller.
		if let result = result, exposureSubmissionService.hasRegistrationToken() {
			return createTestResultViewController(with: result)
		}

		// By default, we show the intro view.
		return createIntroViewController()
	}

	private func createTestResultViewController(with result: TestResult) -> ExposureSubmissionTestResultViewController {
		return ExposureSubmissionTestResultViewController(
			coordinator: self,
			exposureSubmissionService: self.exposureSubmissionService,
			testResult: result
		)
	}
	
	private func createIntroViewController() -> ExposureSubmissionIntroViewController {
		return ExposureSubmissionIntroViewController(coordinator: self)
	}
	
	private func createWarnOthersViewController() -> ExposureSubmissionWarnOthersViewController {
		return BEExposureSubmissionWarnOthersViewController(coordinator: self, exposureSubmissionService: self.exposureSubmissionService)
	}

	private func createSuccessViewController() -> ExposureSubmissionSuccessViewController {
		return ExposureSubmissionSuccessViewController(coordinator: self)
	}
}

extension BEExposureSubmissionCoordinator: BEMobileTestIdGeneratorDelegate {
	func mobileTestIdGenerator(_ generator:BEMobileTestIdGenerator, generatedNewMobileTestId: Bool) {
		showMobileTestIdViewController()
	}
}

extension BEExposureSubmissionCoordinator : BEMobileTestIdViewControllerDelegate {
	
	func mobileTestIdViewControllerFinished(_ vc: BEMobileTestIdViewController) {
		self.navigationController?.dismiss(animated: true)
	}
}

extension BEExposureSubmissionCoordinator : UINavigationControllerDelegate {
	func navigationController(_ controller: UINavigationController, willShow viewController: UIViewController, animated _: Bool) {
		if let navigationController = controller as? ExposureSubmissionNavigationController {
			navigationController.applyDefaultRightBarButtonItem(to: viewController)
		}
	}
	
	func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
		if viewController.isKind(of: BEMobileTestIdViewController.self) {
			navigationController.setViewControllers([viewController], animated: false)
		}
	}
}
