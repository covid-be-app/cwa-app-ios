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

class BESelectCountryViewController: DynamicTableViewController {

	private var countries:[[BECountry]]!
	private var sectionIndexTitles:[String]!
	private var selectedCountry:IndexPath!
	
	private weak var delegate:BESelectCountryViewControllerDelegate?

	init(countries:[BECountry],selectedCountry:BECountry,delegate:BESelectCountryViewControllerDelegate) {
		self.delegate = delegate
		super.init(nibName: nil, bundle: nil)

		self.countries = [[]]
		var firstLetter = String(countries[0].localizedName!.prefix(1))

		self.sectionIndexTitles = [firstLetter]

		countries.forEach{ country in
			if firstLetter == country.localizedName!.prefix(1) {
				self.countries[self.countries.count - 1].append(country)
			} else {
				self.countries.append([country])
				firstLetter = String(country.localizedName!.prefix(1))
				self.sectionIndexTitles.append(firstLetter)
			}
			
			if selectedCountry == country {
				self.selectedCountry = IndexPath(item: self.countries.last!.count - 1, section: self.countries.count - 1)
			}
		}
		
		
	}
	
	
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		tableView.separatorStyle = .none
		tableView.sectionIndexColor = .enaColor(for: .textPrimary2)
		tableView.allowsSelection = true
		
		tableView.register(
			BESelectCountryCell.self,
			forCellReuseIdentifier: CustomCellReuseIdentifiers.countryCell.rawValue
		)
		
		var sections:[DynamicSection] = []
		
		self.countries.forEach{ countries in
			let countryCells:[DynamicCell] = countries.map{ country in
				return DynamicCell.custom(withIdentifier: CustomCellReuseIdentifiers.countryCell,
						configure: { _, cell, _ in
							guard let cell = cell as? BESelectCountryCell else { return }
							
							cell.configure(country: country)
				})

			}
			let firstCountry = countries[0]
			
			sections.append(DynamicSection.section(
				header: .text(String(firstCountry.localizedName.prefix(1))),
				separators:false,
				cells:countryCells))
			
		}
		self.dynamicTableViewModel = DynamicTableViewModel(sections)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		tableView.selectRow(at: selectedCountry, animated: false, scrollPosition: .middle)
	}
	
	func sectionIndexTitles(for tableView: UITableView) -> [String]? {
		return sectionIndexTitles
	}
}

extension BESelectCountryViewController {
	enum CustomCellReuseIdentifiers: String, TableViewCellReuseIdentifiers {
		case countryCell
	}
}

protocol BESelectCountryViewControllerDelegate : class {
	
}


