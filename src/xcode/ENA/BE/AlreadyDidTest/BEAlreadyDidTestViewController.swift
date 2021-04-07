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

class BEAlreadyDidTestViewController: DynamicTableViewController, ENANavigationControllerWithFooterChild {

	private var footerItem = ENANavigationFooterItem()
	
	override var navigationItem :UINavigationItem {
		get {
			return footerItem
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.title = BEAppStrings.BEAlreadyDidTest.title
		navigationFooterItem?.primaryButtonTitle = BEAppStrings.BEAlreadyDidTest.close
		navigationFooterItem?.isPrimaryButtonEnabled = true
		navigationFooterItem?.isSecondaryButtonHidden = true
		
		navigationItem.hidesBackButton = true
		navigationItem.largeTitleDisplayMode = .always

		tableView.separatorStyle = .none
		tableView.backgroundColor = UIColor(enaColor:.background)
		tableView.allowsSelection = false
		tableView.dataSource = self
		tableView.delegate = self
		tableView.register(UINib(nibName: String(describing: ExposureSubmissionStepCell.self), bundle: nil), forCellReuseIdentifier: CustomCellReuseIdentifiers.stepCell.rawValue)
		
		dynamicTableViewModel = DynamicTableViewModel([
			.section(
				header: .image(
					UIImage(named: "Illu_Toolbox_Test"),
					accessibilityLabel: BEAppStrings.BEAlreadyDidTest.imageDescription,
					accessibilityIdentifier: AccessibilityIdentifiers.General.image,
					height: 200
				),
				separators: false,
				cells: [
					.body(text: BEAppStrings.BEAlreadyDidTest.possibilitiesTitle, accessibilityIdentifier: nil),
					ExposureSubmissionDynamicCell.stepCell(bulletPoint: BEAppStrings.BEAlreadyDidTest.possibility1),
					ExposureSubmissionDynamicCell.stepCell(bulletPoint: BEAppStrings.BEAlreadyDidTest.possibility2),
					ExposureSubmissionDynamicCell.stepCell(bulletPoint: BEAppStrings.BEAlreadyDidTest.possibility3)
				]
			)
		])

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		footerView?.primaryButton?.accessibilityIdentifier = BEAccessibilityIdentifiers.BEAlreadyDidTest.close
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	
		// I have no idea why this needs to be here as we don't show a back button anyway
		// but if I keep the back button hidden, the navigation footer button disappears as soon
		// as we scroll the contents. This does not happen if I enable it again
		navigationItem.hidesBackButton = false
	}
	
	// MARK: - ENANavigationControllerWithFooterChild methods.

	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		self.dismiss(animated: true)
	}


}

private extension BEAlreadyDidTestViewController {
	enum CustomCellReuseIdentifiers: String, TableViewCellReuseIdentifiers {
		case stepCell
	}
}
