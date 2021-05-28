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

class BECoviCodeViewController: DynamicTableViewController, ENANavigationControllerWithFooterChild {

	private var footerItem = ENANavigationFooterItem()
	private weak var coordinator: BECoviCodeCoordinator?
	
	override var navigationItem :UINavigationItem {
		get {
			return footerItem
		}
	}
	
	init(_ coordinator: BECoviCodeCoordinator) {
		self.coordinator = coordinator
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.title = BEAppStrings.BECoviCode.title
		navigationFooterItem?.primaryButtonTitle = BEAppStrings.BECoviCode.submit
		navigationFooterItem?.isPrimaryButtonEnabled = true
		navigationFooterItem?.isSecondaryButtonHidden = true
		
		navigationItem.hidesBackButton = true

		tableView.separatorStyle = .none
		tableView.backgroundColor = UIColor(enaColor:.background)
		tableView.allowsSelection = false
		tableView.dataSource = self
		tableView.delegate = self

		dynamicTableViewModel = DynamicTableViewModel([
			.section(
				header: .image(
					UIImage(named: "Illu_Code"),
					accessibilityLabel: AppStrings.ExposureSubmissionIntroduction.accImageDescription,
					accessibilityIdentifier: AccessibilityIdentifiers.General.image,
					height: 200
				),
				separators: false,
				cells: [
					.title2(text: BEAppStrings.BECoviCode.subtitle, accessibilityIdentifier: nil),
					.body(text: BEAppStrings.BECoviCode.explanation, style: .textView(.phoneNumber),
						  accessibilityIdentifier: BEAccessibilityIdentifiers.BECoviCode.explanation)
				]
			)
		])
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		footerView?.primaryButton?.accessibilityIdentifier = BEAccessibilityIdentifiers.BECoviCode.submit
	}

}

extension BECoviCodeViewController {
	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		coordinator?.askForSymptoms()
	}
}
