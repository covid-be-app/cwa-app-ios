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

class BEToolboxViewController: UIViewController {
	

	var toolboxItems = [
		BEToolboxItem(
			text: BEAppStrings.BEToolbox.vaccinationInformation,
			icon: "Icons_Toolbox_Vaccination_Info",
			accessibilityIdentifier: BEAccessibilityIdentifiers.BEToolbox.vaccinationInformation,
			configuration: BEToolboxItem.DetailViewControllerConfiguration(
				title: BEAppStrings.BEToolbox.vaccinationInformationTitle,
				icon: "Illu_Toolbox_Vaccine",
				accessibilityIdentifier: BEAccessibilityIdentifiers.BEToolbox.vaccinationInformation,
				links: [
					BEToolboxItem.DetailLink(
						text: BEAppStrings.BEToolbox.epidemiologicalSituation,
						suffix: nil,
						url: BEAppStrings.BEToolbox.epidemiologicalSituationURL),
					BEToolboxItem.DetailLink(
						text: BEAppStrings.BEToolbox.registerToBeVaccinated,
						suffix: nil,
						url: BEAppStrings.BEToolbox.registerToBeVaccinatedURL)
				])
			),
		BEToolboxItem(
			text: BEAppStrings.BEToolbox.testReservation,
			icon: "Icons_Toolbox_Test",
			accessibilityIdentifier: BEAccessibilityIdentifiers.BEToolbox.testReservation,
			configuration: BEToolboxItem.DetailViewControllerConfiguration(
				title: BEAppStrings.BEToolbox.testReservationTitle,
				icon: "Illu_Toolbox_Test",
				accessibilityIdentifier: BEAccessibilityIdentifiers.BEToolbox.testReservation,
				links: [
					BEToolboxItem.DetailLink(
						text: BEAppStrings.BEToolbox.bookATest,
						suffix: nil,
						url: BEAppStrings.BEToolbox.bookATestURL),
					BEToolboxItem.DetailLink(
						text: BEAppStrings.BEToolbox.bookATestInBrussels,
						suffix: nil,
						url: BEAppStrings.BEToolbox.bookATestInBrusselsURL)
				])
			),
		BEToolboxItem(
			text: BEAppStrings.BEToolbox.quarantineCertificate,
			icon: "Icons_Toolbox_Quarantine",
			accessibilityIdentifier: BEAccessibilityIdentifiers.BEToolbox.quarantineCertificate,
			targetURL: BEAppStrings.BEToolbox.quarantineCertificateURL
			),
		BEToolboxItem(
			text: BEAppStrings.BEToolbox.passengerLocatorForm,
			icon: "Icons_Toolbox_Passenger_Locator_Form",
			accessibilityIdentifier: BEAccessibilityIdentifiers.BEToolbox.passengerLocatorForm,
			configuration: BEToolboxItem.DetailViewControllerConfiguration(
				title: BEAppStrings.BEToolbox.passengerLocatorFormTitle,
				icon: "Illu_Toolbox_Passenger_Locator_Form",
				accessibilityIdentifier: BEAccessibilityIdentifiers.BEToolbox.passengerLocatorForm,
				links: [
					BEToolboxItem.DetailLink(
						text: BEAppStrings.BEToolbox.passengerLocatorFormNL,
						suffix: "NL",
						url: BEAppStrings.BEToolbox.passengerLocatorFormURLNL),
					BEToolboxItem.DetailLink(
						text: BEAppStrings.BEToolbox.passengerLocatorFormFR,
						suffix: "FR",
						url: BEAppStrings.BEToolbox.passengerLocatorFormURLFR),
					BEToolboxItem.DetailLink(
						text: BEAppStrings.BEToolbox.passengerLocatorFormDE,
						suffix: "DE",
						url: BEAppStrings.BEToolbox.passengerLocatorFormURLDE),
					BEToolboxItem.DetailLink(
						text: BEAppStrings.BEToolbox.passengerLocatorFormEN,
						suffix: "EN",
						url: BEAppStrings.BEToolbox.passengerLocatorFormURLEN)
			])
		),
		BEToolboxItem(
			text: BEAppStrings.BEToolbox.testCenter,
			icon: "Icons_Toolbox_Belgium",
			accessibilityIdentifier: BEAccessibilityIdentifiers.BEToolbox.testCenter,
			targetURL: BEAppStrings.BEToolbox.testCenterURL
		)
	]

	@IBOutlet weak var tableView: UITableView!
		
	
	init() {
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View life cycle methods.

	override func viewDidLoad() {
		super.viewDidLoad()
		setupView()
	}

	// MARK: - View setup methods.

	private func setupView() {
		tableView.backgroundColor = .enaColor(for: .separator)
		navigationItem.title = BEAppStrings.BEHome.toolboxTitle
		navigationItem.largeTitleDisplayMode = .always

		tableView.register(UINib(nibName: "BEToolboxCell", bundle: nil), forCellReuseIdentifier: BEToolboxCell.cellIdentifier)
		tableView.rowHeight = UITableView.automaticDimension
		
		setupBackButton()
	}
}

extension BEToolboxViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return toolboxItems.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let item = toolboxItems[indexPath.row]
		
		guard let cell = tableView.dequeueReusableCell(withIdentifier: BEToolboxCell.cellIdentifier, for: indexPath) as? BEToolboxCell else {
			fatalError("")
		}
		
		cell.isAccessibilityElement = true
		cell.accessibilityIdentifier = item.accessibilityIdentifier
		cell.configure(image: item.icon, text: item.text)

		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = toolboxItems[indexPath.row]
		
		if let url = item.targetURL {
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
		} else {
			self.navigationController!.pushViewController(item.viewController, animated: true)
		}
		
	}
}
