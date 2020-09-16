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

protocol BESelectSymptomsDateViewControllerDelegate : class {
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
