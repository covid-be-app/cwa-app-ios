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

import UIKit

protocol BESelectSymptomsDateViewControllerDelegate : AnyObject {
	func selectSymptomsDateViewController(_ vc:BESelectSymptomsDateViewController, selectedDate date:Date)
}

class BESelectSymptomsDateViewController: UIViewController, ENANavigationControllerWithFooterChild {
	private var footerItem = ENANavigationFooterItem()
	
	override var navigationItem :UINavigationItem {
		get {
			return footerItem
		}
	}

	@IBOutlet weak var enterDateExplanationLabel:ENALabel!
	@IBOutlet weak var datePicker:UIDatePicker!

	weak var delegate:BESelectSymptomsDateViewControllerDelegate?
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		navigationFooterItem?.primaryButtonTitle = BEAppStrings.BESelectSymptomsDate.next
		navigationFooterItem?.isPrimaryButtonEnabled = true
		navigationFooterItem?.isSecondaryButtonHidden = true
		navigationItem.title = BEAppStrings.BESelectSymptomsDate.selectDateTitle

		enterDateExplanationLabel.text = BEAppStrings.BESelectSymptomsDate.dateExplanation

		let minimumTimeInterval = TimeInterval(-14*24*60*60)
		datePicker.maximumDate = Date()
		datePicker.minimumDate = Date(timeInterval: minimumTimeInterval, since: datePicker.maximumDate!)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		footerView?.primaryButton?.accessibilityIdentifier = BEAccessibilityIdentifiers.BESelectSymptomsDate.next
	}
}

extension BESelectSymptomsDateViewController {
	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		delegate?.selectSymptomsDateViewController(self, selectedDate: datePicker.date)
	}
}


extension BESelectSymptomsDateViewController {
	func show(_ parentViewController: UIViewController, delegate: BESelectSymptomsDateViewControllerDelegate) {
		self.delegate = delegate
		
		// Since the original code throws all the code for test code registration, test result showing and TEK submission in one big pile inside
		// ExposureSubmissionCoordinator, it's not straightforward to only use the test code flow separately without having to implement protocols
		// and dependencies that are completely useless.
		// Since the viewcontroller used there requires a parent navigation controller with footer buttons
		// the easiest solution is to check if the parent nav controller is of the correct type. If not we embed
		// our viewcontroller in one and show it modally.
		// This is not an ideal solution, but the ideal solution would be to refactor the entire ExposureSubmissionCoordinator,
		// splitting it in different modules (one for code generation, one for showing test results and one for managing the TEK submission)
		// but ain't nobody got time for that right now

		if let vc = parentViewController as? ENANavigationControllerWithFooter {
			vc.pushViewController(self, animated: true)
		} else {
			let navigationController = ENANavigationControllerWithFooter(rootViewController: self)
			navigationController.navigationBar.prefersLargeTitles = true
			self.navigationItem.largeTitleDisplayMode = .always
			navigationController.modalPresentationStyle = .fullScreen
			parentViewController.present(navigationController, animated: true)
		}

	}
}
