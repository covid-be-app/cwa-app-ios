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

class MobileDataUsageTableViewCell: UITableViewCell {
	@IBOutlet var descriptionLabel: UILabel!
	@IBOutlet var toggleSwitch: UISwitch!

	var viewModel: MobileDataUsageViewModel?

	@IBAction func switchToggled(_: Any) {
		viewModel?.isEnabled = toggleSwitch.isOn
	}

	func configure() {
		guard let viewModel = viewModel else { return }

		descriptionLabel.text = BEAppStrings.BEMobileDataUsageSettings.toggleDescription
		toggleSwitch.isOn = viewModel.isEnabled

		setupAccessibility()
	}

	@objc
	func toggle(_ sender: Any) {
		toggleSwitch.isOn.toggle()
		setupAccessibility()
	}

	private func setupAccessibility() {
		accessibilityIdentifier = BEAccessibilityIdentifiers.BEMobileDataUsageSettings.identifier

		isAccessibilityElement = true
		accessibilityTraits = [.button]

		accessibilityCustomActions?.removeAll()

		let actionName = toggleSwitch.isOn ? AppStrings.Settings.statusDisable : AppStrings.Settings.statusEnable
		accessibilityCustomActions = [
			UIAccessibilityCustomAction(name: actionName, target: self, selector: #selector(toggle(_:)))
		]

		accessibilityLabel = BEAppStrings.BEMobileDataUsageSettings.description
		if toggleSwitch.isOn {
			accessibilityValue = BEAppStrings.BESettings.mobileDataActive
		} else {
			accessibilityValue = BEAppStrings.BESettings.mobileDataInactive
		}
	}

}
