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

class ExposureSubmissionTanInputViewController: UIViewController, ENANavigationControllerWithFooterChild {
	// MARK: - Attributes.

	@IBOutlet var scrollView: UIScrollView!
	@IBOutlet var contentView: UIView!
	@IBOutlet var descriptionLabel: UILabel!
	@IBOutlet var errorLabel: UILabel!
	@IBOutlet var errorView: UIView!
	@IBOutlet var tanInput: ENATanInput! { didSet { tanInput.delegate = self } }

	var initialTan: String?
	private(set) weak var exposureSubmissionService: ExposureSubmissionService?
	private(set) weak var coordinator: ExposureSubmissionCoordinating?

	// MARK: - Initializers.

	init?(coder: NSCoder, coordinator: ExposureSubmissionCoordinating, exposureSubmissionService: ExposureSubmissionService) {
		self.coordinator = coordinator
		self.exposureSubmissionService = exposureSubmissionService
		super.init(coder: coder)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View lifecycle methods.

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = AppStrings.ExposureSubmissionTanEntry.title

		navigationFooterItem?.primaryButtonTitle = AppStrings.ExposureSubmissionTanEntry.submit
		navigationFooterItem?.isPrimaryButtonEnabled = false

		descriptionLabel.text = AppStrings.ExposureSubmissionTanEntry.description
		errorView.alpha = 0
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if let tan = initialTan {
			tanInput.clear()
			tanInput.insertText(tan)
			initialTan = nil
		} else {
			DispatchQueue.main.async {
				self.tanInput.becomeFirstResponder()
			}
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		tanInput.resignFirstResponder()
	}
}

// MARK: - ENANavigationControllerWithFooterChild methods.

extension ExposureSubmissionTanInputViewController {
	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		tanInput.resignFirstResponder()
		submitTan()
	}

	@discardableResult
	func submitTan() -> Bool {
		guard tanInput.isValid && tanInput.isChecksumValid else { return false }

		navigationFooterItem?.isPrimaryButtonLoading = true
		navigationFooterItem?.isPrimaryButtonEnabled = false

		// If teleTAN is correct, show Alert Controller
		// to check permissions to request TAN.
		let teleTan = tanInput.text

		exposureSubmissionService?.getRegistrationToken(forKey: .teleTan(teleTan)) { result in

			switch result {
			case let .failure(error):

				let alert = Self.setupErrorAlert(
					message: error.localizedDescription,
					completion: {
						self.navigationFooterItem?.isPrimaryButtonLoading = false
						self.navigationFooterItem?.isPrimaryButtonEnabled = true
						self.tanInput.becomeFirstResponder()
					})
				self.present(alert, animated: true, completion: nil)

			case .success:
				// A TAN always indicates a positive test result.
				self.coordinator?.showTestResultScreen(with: .positive)
			}
		}

		return true
	}
}

	// MARK: - ENATanInputDelegate
extension ExposureSubmissionTanInputViewController: ENATanInputDelegate {
	func enaTanInputDidBeginEditing(_ tanInput: ENATanInput) {
		let rect = contentView.convert(tanInput.frame, from: tanInput)
		scrollView.scrollRectToVisible(rect, animated: true)
	}

	func enaTanInput(_ tanInput: ENATanInput, didChange text: String, isValid: Bool, isChecksumValid: Bool, isBlocked: Bool) {
		navigationFooterItem?.isPrimaryButtonEnabled = (isValid && isChecksumValid)

		UIView.animate(withDuration: CATransaction.animationDuration()) {
			if isValid && !isChecksumValid {
				self.errorLabel.text = AppStrings.ExposureSubmissionTanEntry.invalidError
				self.errorView.alpha = 1
			} else if isBlocked {
				self.errorLabel.text = AppStrings.ExposureSubmissionTanEntry.invalidCharacterError
				self.errorView.alpha = 1
			} else {
				self.errorView.alpha = 0
			}

			self.view.layoutIfNeeded()
		}
	}

	func enaTanInputDidTapReturn(_ tanInput: ENATanInput) -> Bool {
		return submitTan()
	}
}
