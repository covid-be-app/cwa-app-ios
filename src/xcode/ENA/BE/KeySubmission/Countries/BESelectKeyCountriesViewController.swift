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
import ExposureNotification

class BESelectKeyCountriesViewController: DynamicTableViewController, ENANavigationControllerWithFooterChild {

	private var footerItem = ENANavigationFooterItem()
	
	override var navigationItem :UINavigationItem {
		get {
			return footerItem
		}
	}
	
	private let exposureKeys:[ENTemporaryExposureKey]
	private var selectedCountries:[BECountry]
	private let countries:[BECountry]
	private let coordinator:BEExposureSubmissionCoordinator
	private let service:BEExposureSubmissionService
	
	private var editedKeyIndex:Int?
	
	init(service:BEExposureSubmissionService,coordinator:BEExposureSubmissionCoordinator,exposureKeys:[ENTemporaryExposureKey]) {
		self.coordinator = coordinator
		self.service = service
		self.exposureKeys = exposureKeys
		let countries = BECountry.load()
		self.countries = countries
		
		selectedCountries = exposureKeys.map{ _ in
			return countries.defaultCountry
		}
		

		// if we don't add the nib name the dynamic table view controller superclass doesn't load it but just creates a tableview as main view
		super.init(nibName: "BESelectKeyCountriesViewController", bundle: Bundle.main)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		tableView.register(
			BESelectKeyCountryCell.self,
			forCellReuseIdentifier: CustomCellReuseIdentifiers.keyCell.rawValue
		)

		navigationFooterItem?.primaryButtonTitle = BEAppStrings.BESelectKeyCountries.sendKeys
		navigationItem.title = BEAppStrings.BESelectKeyCountries.title
		
		let headSection = DynamicSection.section(
			separators: false,
			cells: [.subheadline(text: BEAppStrings.BESelectKeyCountries.explanation, accessibilityIdentifier: BEAccessibilityIdentifiers.BESelectKeyCountries.explanation)])
		
		let keyCells:[DynamicCell] = exposureKeys.enumerated().map{ (index,key) in
			return DynamicCell.custom(
				withIdentifier: CustomCellReuseIdentifiers.keyCell,
				action: .execute(block: { vc in
					guard let selectCountriesViewController = vc as? BESelectKeyCountriesViewController else {
						fatalError("Wrong viewcontroller")
					}
					
					selectCountriesViewController.selectCountry(forKeyAtIndex: index)
				}),
				configure: { _, cell, _ in
					guard let cell = cell as? BESelectKeyCountryCell else { return }
					cell.configure(
						key:key,
						country:self.selectedCountries[index]
					)
			})

		}
		
		self.dynamicTableViewModel = DynamicTableViewModel([
			headSection,
			.section(
				separators:true,
				cells:keyCells
			)
		])
		
		footerItem.isPrimaryButtonEnabled = true
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		footerView?.primaryButton.accessibilityIdentifier = BEAccessibilityIdentifiers.BESelectKeyCountries.shareIds
	}
	
	private func selectCountry(forKeyAtIndex index:Int) {
		editedKeyIndex = index
		let key = exposureKeys[index]
		coordinator.showSelectCountryForKey(
			countries: countries,
			selectedCountry: selectedCountries[index],
			keyDate: key.rollingStartNumber.date,
			delegate:self
		)
	}
}

extension BESelectKeyCountriesViewController {
	enum CustomCellReuseIdentifiers: String, TableViewCellReuseIdentifiers {
		case keyCell
	}
}

extension BESelectKeyCountriesViewController {
	func navigationController(_ navigationController: ENANavigationControllerWithFooter, didTapPrimaryButton button: UIButton) {
		service.submitExposure(keys: exposureKeys, countries: selectedCountries) { error in
			if let error = error {
				logError(message: "error: \(error.localizedDescription)", level: .error)
				let alert = self.setupErrorAlert(message: error.localizedDescription)
				self.present(alert, animated: true, completion: {
					self.navigationFooterItem?.isPrimaryButtonLoading = false
					self.navigationFooterItem?.isPrimaryButtonEnabled = true
				})
			} else {
				self.coordinator.showThankYouScreen()
			}
		}
	}
}

extension BESelectKeyCountriesViewController : BESelectCountryViewControllerDelegate {
	func selectCountryViewController(_ vc:BESelectCountryViewController,selectedCountry country:BECountry) {
		guard let keyIndex = editedKeyIndex else {
			fatalError("Wrong key index")
		}
		
		selectedCountries[keyIndex] = country
		tableView.reloadData()
	}
}
