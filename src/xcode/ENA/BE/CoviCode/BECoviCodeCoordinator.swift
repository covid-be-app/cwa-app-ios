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

class BECoviCodeCoordinator: NSObject {
	private weak var parentViewController:UINavigationController!
	private let exposureSubmissionService: BEExposureSubmissionService
	private var navigationController: ExposureSubmissionNavigationController!
	private var sendCodesAction: UIAlertAction?
	
	var delegate: ExposureSubmissionCoordinatorDelegate?
	
	init(exposureSubmissionService: BEExposureSubmissionService, parentViewController:UINavigationController, delegate: ExposureSubmissionCoordinatorDelegate) {
		self.delegate = delegate
		self.parentViewController = parentViewController
		self.exposureSubmissionService = exposureSubmissionService
	}
	
	func start() {
		let initialVC = BECoviCodeViewController(self)

		/// The navigation controller keeps a strong reference to the coordinator. The coordinator only reaches reference count 0
		/// when UIKit dismisses the navigationController.
		let navigationController = createNavigationController(rootViewController: initialVC)
		navigationController.delegate = self
		parentViewController.present(navigationController, animated: true)
		self.navigationController = navigationController

	}

	private func createNavigationController(rootViewController vc:UIViewController)  -> ExposureSubmissionNavigationController {
		let vc = ExposureSubmissionNavigationController(coordinator: self, rootViewController: vc)
		vc.doKeyboardObservation = false
		
		return vc
	}

	func askForSymptoms() {
		let alert = UIAlertController(
			title: BEAppStrings.BEExposureSubmission.symptomsExplanation,
			message: nil,
			preferredStyle: .alert
		)
		let yesAction = UIAlertAction(title: BEAppStrings.BEExposureSubmission.yes,
										 style: .default, handler: { _ in
											self.showSelectSymptomsDateViewController()
		})

		let noAction = UIAlertAction(title: BEAppStrings.BEExposureSubmission.no,
										 style: .default, handler: { _ in
											self.requestCoviCode()
		})

		alert.addAction(yesAction)
		alert.addAction(noAction)

		navigationController.present(alert, animated: true)
	}
	
	private func showSelectSymptomsDateViewController() {
		let vc = BESelectSymptomsDateViewController()
		
		vc.show(navigationController, delegate: self)
	}
	
	private func requestCoviCode(_ selectedDate: Date? = nil) {
		let alert = UIAlertController(
			title: BEAppStrings.BECoviCode.enterCodeTitle,
			message: BEAppStrings.BECoviCode.enterCodeDescription,
			preferredStyle: .alert
		)
		
		alert.addTextField{ textField in
			textField.delegate = self
			textField.keyboardType = .numberPad
		}
		
		let okAction = UIAlertAction(title: BEAppStrings.BECoviCode.ok,
										 style: .default, handler: { [weak self] _ in
											guard let self = self else { return }

											guard
												let textFields = alert.textFields,
												let code = textFields[0].text else {
												fatalError("")
											}
											
											self.submitExposureKeys(coviCode: code, symptomsStartDate: selectedDate)
		})

		okAction.isEnabled = false
		
		let noAction = UIAlertAction(title: BEAppStrings.BECoviCode.cancel,
									 style: .cancel, handler: { _ in
		})

		alert.addAction(okAction)
		alert.addAction(noAction)

		sendCodesAction = okAction
		
		navigationController.present(alert, animated: true)
	}
	
	private	func submitExposureKeys(coviCode: String, symptomsStartDate: Date?) {
		exposureSubmissionService.submitExposureWithCoviCode(coviCode: coviCode, symptomsStartDate: symptomsStartDate) { error in
			
			if let error = error {
				switch error {
				case .noKeys:
					self.exposureSubmissionService.finalizeSubmissionWithoutKeys()
					self.showThankYouScreen()
				default:
					logError(message: "error: \(error.localizedDescription)", level: .error)
					self.showErrorAlert(message: error.localizedDescription)
				}
			} else {
				self.showThankYouScreen()
			}
		}
	}
	
	private func showErrorAlert(message: String) {
		let alert = UIViewController.setupErrorAlert(message: message, completion: {
			self.navigationController.dismiss(animated: true)
		})
		self.navigationController.present(alert, animated: true)
	}
	
	private func showThankYouScreen() {
		let vc = createSuccessViewController()
		self.navigationController.pushViewController(vc, animated: true)
	}

	private func createSuccessViewController() -> ExposureSubmissionSuccessViewController {
		return ExposureSubmissionSuccessViewController(coordinator: self)
	}
}

extension BECoviCodeCoordinator: UITextFieldDelegate {
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let text = textField.text as NSString?
		if let resultString = text?.replacingCharacters(in: range, with: string) {
			
			sendCodesAction?.isEnabled = resultString.count == 12
			
			return resultString.count < 13
		}
		
		return true
	}
}

extension BECoviCodeCoordinator : BESelectSymptomsDateViewControllerDelegate {
	func selectSymptomsDateViewController(_ vc:BESelectSymptomsDateViewController, selectedDate date:Date) {
		requestCoviCode(date)
	}
}

extension BECoviCodeCoordinator : UINavigationControllerDelegate {
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

extension BECoviCodeCoordinator: ExposureSubmissionCoordinating {
	
	func dismiss() {
		parentViewController.dismiss(animated: true) {
			self.delegate?.exposureSubmissionCoordinatorWillDisappear(self)
		}
	}
	
	func resetApp() {
		parentViewController.dismiss(animated: true) {
			self.delegate?.exposureSubmissionCoordinatorRequestsAppReset()
		}

	}

}
