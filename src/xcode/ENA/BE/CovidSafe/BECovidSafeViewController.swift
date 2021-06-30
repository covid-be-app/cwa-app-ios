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

class BECovidSafeViewController: UIViewController {

	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var button: UIButton!
	@IBOutlet weak var contentView: UIView!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		contentView.backgroundColor = .enaColor(for: .separator)
		navigationItem.title = BEAppStrings.BECovidSafe.title
		navigationItem.largeTitleDisplayMode = .always
		
		titleLabel.text = BEAppStrings.BECovidSafe.appTitle
		subtitleLabel.text = BEAppStrings.BECovidSafe.appSubtitle
		button.setTitle(BEAppStrings.BECovidSafe.appButton, for: .normal)
		button.accessibilityIdentifier = BEAccessibilityIdentifiers.BECovidSafe.button
		button.accessibilityLabel = BEAppStrings.BECovidSafe.appTitle
	}
	
	@IBAction func buttonPressed() {
		let url = URL(string: "https://cert-app.be/launch")!
		if UIApplication.shared.canOpenURL(url) {
			UIApplication.shared.open(url, completionHandler: nil)
		}
	}
}
