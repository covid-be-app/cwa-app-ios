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

// Links a (new?) mobile test id to an activation code that we received from the government
// url format: https://coronalert.be/en/corona-alert-form/?pcr=0000000000000000

protocol BEMobileTestIdActivatorDelegate: class {
	func mobileTestIdActivatorFinished(_: BEMobileTestIdActivator)
}

class BEMobileTestIdActivator {
	
	/// the paths we accept for this flow, each language has its own path
	/// https://coronalert.be/en/corona-alert-form/?pcr=0000000000000000
	/// https://coronalert.be/nl/coronalert-formulier/?pcr=0000000000000000
	/// ...
	private static let paths = ["corona-alert-form","coronalert-formulier","coronalert-formular","formulaire-coronalert"]

	private let exposureSubmissionService: BEExposureSubmissionService
	private let url:URL
	
	/// the viewcontroller that will contain all the generated view controllers for this flow
	private weak var parentViewController:UINavigationController!

	/// the container viewcontroller for the form
	private var activateMobileTestIdNavigationController:UINavigationController?
	
	private var mobileTestIdGenerator: BEMobileTestIdGenerator?
	private var generatedNewMobileTestId:Bool = false
	
	private weak var delegate: BEMobileTestIdActivatorDelegate?

	init?(_ exposureSubmissionService: BEExposureSubmissionService, parentViewController: UINavigationController, url:URL, delegate:BEMobileTestIdActivatorDelegate?) {
		
		if !Self.validateURL(url) {
			return nil
		}
		
		self.exposureSubmissionService = exposureSubmissionService
		self.parentViewController = parentViewController
		self.delegate = delegate
		self.url = url
		
		self.mobileTestIdGenerator = BEMobileTestIdGenerator(exposureSubmissionService: exposureSubmissionService, parentViewController: parentViewController, delegate: self)
	}

	func run() {
		if let presentedViewController = parentViewController.presentedViewController {
			presentedViewController.dismiss(animated: false) {
				self.mobileTestIdGenerator?.generate()
			}
		} else {
			self.mobileTestIdGenerator?.generate()
		}

	}

	// MARK: - URL validation
	
	static private func validateURL(_ url:URL) -> Bool {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			logError(message: "URL problem \(url)")
			return false
		}
		
		if Self.paths.first(where: { components.path.contains($0) }) == nil {
			logError(message: "Wrong path \(components.path)")
			return false
		}
		
		guard let activationCode = getActivationCodeFromURL(components) else {
			logError(message: "Activation code problem \(components)")
			return false
		}
		
		log(message: "Activation code \(activationCode)")
		
		return true
	}
	
	static private func getActivationCodeFromURL(_ components:URLComponents) -> String? {
		let activationCodeParameterName = "pcr"

		guard let queryItems = components.queryItems else {
			logError(message: "URL query items problem \(components)")
			return nil
		}
		
		if queryItems.count != 1 {
			logError(message: "Wrong number of query items")
			return nil
		}

		let queryItem = queryItems[0]
		
		if queryItem.name != activationCodeParameterName {
			logError(message: "Wrong query item name \(queryItem.name)")
			return nil
		}

		guard let activationCodeValue = queryItem.value else {
			logError(message: "Missing activation code")
			return nil
		}
		
		if activationCodeValue.count != 16  {
			logError(message: "Wrong activation code length")
			return nil
		}
		
		let onlyAlphaNumeric = activationCodeValue.reduce(true) { (onlyAlphaNumeric, character) -> Bool in
			return onlyAlphaNumeric && (character.isLetter || character.isNumber)
		}
		
		if onlyAlphaNumeric == false {
			logError(message: "Activation code should only contain alphanumeric characters")
			return nil
		}

		return activationCodeValue
	}
	
	// MARK: - Actions
	@objc func close() {
		activateMobileTestIdNavigationController?.dismiss(animated: true) {
			if self.generatedNewMobileTestId {
				self.exposureSubmissionService.deleteTest()
			}
			self.delegate?.mobileTestIdActivatorFinished(self)
		}
	}
}

extension BEMobileTestIdActivator: BEActivateMobileTestIdViewControllerDelegate {
	
	func activateMobileTestIdViewControllerCancelled(_: BEActivateMobileTestIdViewController) {
		activateMobileTestIdNavigationController?.dismiss(animated: true) {
			if self.generatedNewMobileTestId {
				self.exposureSubmissionService.deleteTest()
			}
			self.delegate?.mobileTestIdActivatorFinished(self)
		}
	}
	
	func activateMobileTestIdViewControllerFinished(_ viewController: BEActivateMobileTestIdViewController) {
		let alert = viewController.setupErrorAlert(title: BEAppStrings.BEMobileTestIdActivator.testActivatedTitle, message: BEAppStrings.BEMobileTestIdActivator.testActivatedMessage)
		
		activateMobileTestIdNavigationController?.dismiss(animated: true) {
			self.parentViewController.present(alert, animated: true)
			self.delegate?.mobileTestIdActivatorFinished(self)
		}
	}
}

extension BEMobileTestIdActivator: BEMobileTestIdGeneratorDelegate {
	
	func mobileTestIdGenerator(_ generator:BEMobileTestIdGenerator, generatedNewMobileTestId: Bool) {
		self.generatedNewMobileTestId = generatedNewMobileTestId
		openWebForm()
	}

	private func openWebForm() {
		guard let mobileTestId = exposureSubmissionService.mobileTestId else {
			log(message: "Mobile test id error")
			return
		}
		
		let navController = createNavigationController(withURL:url, mobileTestId: mobileTestId)
		activateMobileTestIdNavigationController = navController
		
		if let presentedViewController = parentViewController.presentedViewController {
			presentedViewController.dismiss(animated: false) {
				self.parentViewController.present(navController, animated: true)
			}
		} else {
			parentViewController.present(navController, animated: true)
		}
		
		return
	}
	
	private func createNavigationController(withURL url:URL, mobileTestId:BEMobileTestId) -> UINavigationController {
		let viewController = BEActivateMobileTestIdViewController(mobileTestId: mobileTestId, url: url, delegate: self)
		let navigationController = UINavigationController(rootViewController:viewController)
		
		let closeButton = UIButton(type: .custom)
		closeButton.setImage(UIImage(named: "Icons - Close"), for: .normal)
		closeButton.setImage(UIImage(named: "Icons - Close - Tap"), for: .highlighted)
		closeButton.addTarget(self, action: #selector(close), for: .primaryActionTriggered)

		let barButtonItem = UIBarButtonItem(customView: closeButton)
		barButtonItem.accessibilityLabel = AppStrings.AccessibilityLabel.close
		barButtonItem.accessibilityIdentifier = AccessibilityIdentifiers.AccessibilityLabel.close

		viewController.navigationItem.rightBarButtonItem = barButtonItem
		viewController.navigationItem.title = BEAppStrings.BEMobileTestIdActivator.linkTestToPhoneTitle

		navigationController.modalPresentationStyle = .fullScreen
	
		return navigationController
	}
	
}
