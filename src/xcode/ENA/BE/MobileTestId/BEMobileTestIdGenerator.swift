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

protocol BEMobileTestIdGeneratorDelegate: class {
	/// When this is called, a mobile test id will always exist in BEExposureSubmissionService
	/// the second parameter only communicates if it is a newly generated one or not
	func mobileTestIdGenerator(_ generator:BEMobileTestIdGenerator, generatedNewMobileTestId: Bool)
}

/// This class generates a new mobile test id inside BEExposureSubmissionService, if no test id is present
class BEMobileTestIdGenerator {
	private weak var delegate:BEMobileTestIdGeneratorDelegate?
	private weak var parentViewController:UINavigationController!
	private let exposureSubmissionService: BEExposureSubmissionService
	
	init(exposureSubmissionService: BEExposureSubmissionService, parentViewController:UINavigationController, delegate: BEMobileTestIdGeneratorDelegate) {
		self.delegate = delegate
		self.parentViewController = parentViewController
		self.exposureSubmissionService = exposureSubmissionService
	}
	
	func generate() {
		if exposureSubmissionService.mobileTestId != nil {
			delegate?.mobileTestIdGenerator(self, generatedNewMobileTestId: false)
			return
		}
		
		generateNewMobileTestId()
	}
	
	private func generateNewMobileTestId() {
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
											self.exposureSubmissionService.generateMobileTestId(nil)
											self.delegate?.mobileTestIdGenerator(self, generatedNewMobileTestId: true)
		})

		alert.addAction(yesAction)
		alert.addAction(noAction)

		parentViewController.present(alert, animated: true)
	}
	
	private func showSelectSymptomsDateViewController() {
		let vc = BESelectSymptomsDateViewController()
		vc.delegate = self
		
		// Since the original code throws all the code for test code registration, test result showing and TEK submission in one big pile inside
		// ExposureSubmissionCoordinator, it's not straightforward to only use the test code flow separately without having to implement protocols
		// and dependencies that are completely useless.
		// Since the viewcontroller used there requires a parent navigation controller with footer buttons
		// the easiest solution is to check if the parent nav controller is of the correct type. If not we embed
		// our viewcontroller in one and show it modally.
		// This is not an ideal solution, but the ideal solution would be to refactor the entire ExposureSubmissionCoordinator,
		// splitting it in different modules (one for code generation, one for showing test results and one for managing the TEK submission)
		// but ain't nobody got time for that right now
		
		if self.parentViewController is ENANavigationControllerWithFooter {
			self.parentViewController.pushViewController(vc, animated: true)
		} else {
			let navigationController = ENANavigationControllerWithFooter(rootViewController: vc)
			navigationController.navigationBar.prefersLargeTitles = true
			vc.navigationItem.largeTitleDisplayMode = .always
			navigationController.modalPresentationStyle = .fullScreen
			self.parentViewController.present(navigationController, animated: true)
		}
	}
}

extension BEMobileTestIdGenerator : BESelectSymptomsDateViewControllerDelegate {
	func selectSymptomsDateViewController(_ vc:BESelectSymptomsDateViewController, selectedDate date:Date) {
		self.exposureSubmissionService.generateMobileTestId(date)
		self.delegate?.mobileTestIdGenerator(self, generatedNewMobileTestId: true)
	}
}
