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

class BEExposureSubmissionCoordinator : ExposureSubmissionCoordinating {

	
	// MARK: - Attributes.

	/// - NOTE: The delegate is called by the `viewWillDisappear(_:)` method of the `navigationController`.
	weak var delegate: ExposureSubmissionCoordinatorDelegate?
	weak var parentNavigationController: UINavigationController?

	weak var navigationController: UINavigationController?

	/// - NOTE: We need a strong (aka non-weak) reference here.
	let exposureSubmissionService: BEExposureSubmissionService

	
	private weak var selectCountryDelegate:BESelectCountryViewControllerDelegate?
	
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
			title: BEAppStrings.BEExposureSubmission.symptomsExplanation,
			message: nil,
			preferredStyle: .alert
		)
		let yesAction = UIAlertAction(title: BEAppStrings.BEExposureSubmission.yes,
										 style: .default, handler: { _ in
											self.exposureSubmissionService.acceptPairing()
											let vc = BESelectSymptomsDateViewController()
											vc.delegate = self
											self.push(vc)
		})

		let noAction = UIAlertAction(title: BEAppStrings.BEExposureSubmission.no,
										 style: .default, handler: { _ in
											self.exposureSubmissionService.acceptPairing()
											self.showMobileTestIdViewController()
		})

		alert.addAction(yesAction)
		alert.addAction(noAction)

		present(alert)
	}

	func showWarnOthersScreen() {
		let vc = createWarnOthersViewController()
		push(vc)
	}

	func showThankYouScreen() {
		let vc = createSuccessViewController()
		push(vc)
	}
	
	func showSelectCountries(_ exposureKeys:[ENTemporaryExposureKey]) {
		let vc = BESelectKeyCountriesViewController(service:exposureSubmissionService,coordinator:self,exposureKeys:exposureKeys)

		push(vc)
	}
	
	func showSelectCountryForKey(countries:[BECountry],selectedCountry:BECountry,keyDate:Date,delegate:BESelectCountryViewControllerDelegate) {
		let vc = BESelectCountryViewController(
			countries:countries,
			selectedCountry:selectedCountry,
			delegate:self)
		
		selectCountryDelegate = delegate
		
		let dateFormatter = DateFormatter()
		dateFormatter.timeStyle = .none
		dateFormatter.dateStyle = .medium
		let dateString = dateFormatter.string(from:keyDate)

		vc.title = dateString
		push(vc)
	}


	// MARK: - Methods no longer used


	func showHotlineScreen() {
		fatalError("Deprecated")
	}
	
	func showTanScreen() {
		fatalError("Deprecated")
	}

	func showQRScreen(qrScannerDelegate: ExposureSubmissionQRScannerDelegate) {
		fatalError("Deprecated")
	}

	func showTestResultScreen(with result: TestResult) {
		fatalError("Deprecated")
	}
	
	func showMobileTestIdViewController(symptomsDate:Date? = nil) {
		let vc = BEMobileTestIdViewController(symptomsDate: symptomsDate)
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
		return AppStoryboard.exposureSubmission.initiateInitial { coder in
			return ExposureSubmissionNavigationController(coder: coder, coordinator: self, rootViewController: vc)
		}
	}
	
	private func getInitialViewController(with result: TestResult? = nil) -> UIViewController {
		#if UITESTING
		if ProcessInfo.processInfo.arguments.contains("-negativeResult") {
			return createTestResultViewController(with: .negative)
		}

		// :BE: add positive
		if ProcessInfo.processInfo.arguments.contains("-positiveResult") {
			return createTestResultViewController(with: .positive)
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
			BEExposureSubmissionWarnOthersViewController(coder: coder, coordinator: self, exposureSubmissionService: self.exposureSubmissionService)
		}
	}

	private func createSuccessViewController() -> ExposureSubmissionSuccessViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionSuccessViewController.self) { coder -> UIViewController? in
			ExposureSubmissionSuccessViewController(coder: coder, coordinator: self)
		}
	}
}

extension BEExposureSubmissionCoordinator : BEMobileTestIdViewControllerDelegate {
	
	func mobileTestIdViewController(_ vc: BEMobileTestIdViewController, finshedWithMobileTestId mobileTestId: BEMobileTestId) {
		exposureSubmissionService.mobileTestId = mobileTestId
		self.navigationController?.dismiss(animated: true)
	}
}

extension BEExposureSubmissionCoordinator : BESelectSymptomsDateViewControllerDelegate {
	func selectSymptomsDateViewController(_ vc: BESelectSymptomsDateViewController, selectedDate date: Date) {
		showMobileTestIdViewController(symptomsDate: date)
	}
}

extension BEExposureSubmissionCoordinator : BESelectCountryViewControllerDelegate {
	func selectCountryViewController(_ vc: BESelectCountryViewController, selectedCountry country: BECountry) {
		selectCountryDelegate?.selectCountryViewController(vc, selectedCountry: country)
		self.navigationController?.popViewController(animated: true)
		selectCountryDelegate = nil
	}
}
