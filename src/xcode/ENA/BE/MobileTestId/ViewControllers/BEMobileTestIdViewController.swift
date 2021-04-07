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

protocol BEMobileTestIdViewControllerDelegate : class {
	func mobileTestIdViewControllerFinished(_ vc:BEMobileTestIdViewController)
}

class BEMobileTestIdViewController: DynamicTableViewController, ENANavigationControllerWithFooterChild {

	private var footerItem = ENANavigationFooterItem()
	
	override var navigationItem :UINavigationItem {
		get {
			return footerItem
		}
	}

	weak var delegate:BEMobileTestIdViewControllerDelegate?
	private let mobileTestId:BEMobileTestId
	
	init(_ mobileTestId: BEMobileTestId) {
		self.mobileTestId = mobileTestId
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.title = BEAppStrings.BEMobileTestId.title
		navigationFooterItem?.primaryButtonTitle = BEAppStrings.BEMobileTestId.close
		navigationFooterItem?.isPrimaryButtonEnabled = true
		navigationFooterItem?.isSecondaryButtonHidden = true
		
		navigationItem.hidesBackButton = true

		tableView.separatorStyle = .none
		tableView.backgroundColor = UIColor(enaColor:.background)
		tableView.allowsSelection = false

		setupView()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		footerView?.primaryButton?.accessibilityIdentifier = BEAccessibilityIdentifiers.BEMobileTestId.save
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	
		// I have no idea why this needs to be here as we don't show a back button anyway
		// but if I keep the back button hidden, the navigation footer button disappears as soon
		// as we scroll the contents. This does not happen if I enable it again
		navigationItem.hidesBackButton = false
	}
	
	private func setupView() {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none

		tableView.dataSource = self
		tableView.delegate = self
		tableView.register(UINib(nibName: String(describing: ExposureSubmissionStepCell.self), bundle: nil), forCellReuseIdentifier: CustomCellReuseIdentifiers.stepCell.rawValue)

		// We do 2 things here
		// - enable the copy functionality on the label (implemented in a UILabel extension)
		// - remove the trailing constraint on the label, because by default in the German code the label is spanning the entire width of the containing cell, minus margins
		//   the problem with that is that the "copy" text does not appear centered above the code, so we remove that constraint. No need for it since the code will never be multi-line
		let codeCell = DynamicCell.headline(text:mobileTestId.fullString, accessibilityIdentifier: nil) { viewController, cell, indexPath in
			if
				let textLabel = cell.textLabel,
				let superview = textLabel.superview {
				textLabel.isCopyingEnabled = true
				
				let constraint = superview.constraints.first{ constraint in
					return constraint.firstAnchor == textLabel.trailingAnchor || constraint.secondAnchor == textLabel.trailingAnchor
				}
				
				constraint?.isActive = false
			}
		}
		
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
					.title2(text: BEAppStrings.BEMobileTestId.subtitle, accessibilityIdentifier: nil),
					.body(text: BEAppStrings.BEMobileTestId.saveExplanation,
						  accessibilityIdentifier: BEAccessibilityIdentifiers.BEMobileTestId.saveExplanation),
					.title2(text: BEAppStrings.BEMobileTestId.dateInfectious, accessibilityIdentifier: nil),
					.headline(text: dateFormatter.string(from:mobileTestId.datePatientInfectious.dateWithoutTime!), accessibilityIdentifier: nil),
					.title2(text: BEAppStrings.BEMobileTestId.code, accessibilityIdentifier: nil),
					codeCell,
					.body(text: BEAppStrings.BEMobileTestId.saveExplanation2,
						  accessibilityIdentifier: BEAccessibilityIdentifiers.BEMobileTestId.saveExplanation2),
				]
			)
		])
	}
}

private extension BEMobileTestIdViewController {
	enum CustomCellReuseIdentifiers: String, TableViewCellReuseIdentifiers {
		case stepCell
	}
}

extension BEMobileTestIdViewController {
	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		delegate?.mobileTestIdViewControllerFinished(self)
	}
}
