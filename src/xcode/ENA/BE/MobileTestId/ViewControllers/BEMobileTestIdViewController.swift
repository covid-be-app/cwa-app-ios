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
	func mobileTestIdViewController(_ vc:BEMobileTestIdViewController, finshedWithMobileTestId mobileTestId:BEMobileTestId )
}

class BEMobileTestIdViewController: UIViewController, ENANavigationControllerWithFooterChild {

	private var footerItem = ENANavigationFooterItem()
	
	override var navigationItem :UINavigationItem {
		get {
			return footerItem
		}
	}

	@IBOutlet weak var codeLabel:UILabel!
	@IBOutlet weak var qrCodeImageView:UIImageView!
	@IBOutlet weak var saveExplanationLabel:UILabel!
	
	weak var delegate:BEMobileTestIdViewControllerDelegate?
	private let mobileTestId:BEMobileTestId
	
	init(symptomsDate:Date? = nil) {
		let datePatientInfectious = BEMobileTestId.calculateDatePatientInfectious(symptomsStartDate: symptomsDate)
		self.mobileTestId = BEMobileTestId(datePatientInfectious: String.fromDateWithoutTime(date:datePatientInfectious))
		
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.title = BEAppStrings.BEMobileTestId.title
		navigationFooterItem?.primaryButtonTitle = BEAppStrings.BEMobileTestId.save
		navigationFooterItem?.isPrimaryButtonEnabled = true
		saveExplanationLabel.text = BEAppStrings.BEMobileTestId.saveExplanation

		let qrCodeImage = UIImage.generateQRCode(mobileTestId.fullString, size: qrCodeImageView.bounds.size.width * self.view.contentScaleFactor)
		
		qrCodeImageView.image = qrCodeImage
		codeLabel.text = mobileTestId.fullString
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		footerView?.primaryButton?.accessibilityIdentifier = BEAccessibilityIdentifiers.BEMobileTestId.save
	}
}


extension BEMobileTestIdViewController {
	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		delegate?.mobileTestIdViewController(self, finshedWithMobileTestId: mobileTestId)
	}
}
