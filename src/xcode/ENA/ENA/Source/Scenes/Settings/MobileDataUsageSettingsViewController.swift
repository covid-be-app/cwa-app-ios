// Corona-Warn-App
//
// SAP SE and all other contributors
//
// Modified by Devside SRL
//
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

import UIKit

class MobileDataUsageSettingsViewController: UIViewController {
	@IBOutlet var illustrationImageView: UIImageView!
	@IBOutlet var titleLabel: ENALabel!
	@IBOutlet var descriptionLabel: ENALabel!

	@IBOutlet var tableView: UITableView!

	@IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!

	let store: Store

	init(store: Store) {
		self.store = store

		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.delegate = self
		tableView.dataSource = self
		tableView.separatorColor = .enaColor(for: .hairline)
		tableView.register(UINib(nibName: String(describing: MobileDataUsageTableViewCell.self), bundle: nil), forCellReuseIdentifier: "mobileDataUsage")
		self.view.backgroundColor = .enaColor(for: .background)
		navigationItem.title = BEAppStrings.BEMobileDataUsageSettings.navigationBarTitle
		navigationController?.navigationBar.prefersLargeTitles = true

		setupView()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		tableView.layoutIfNeeded()
		tableViewHeightConstraint.constant = tableView.contentSize.height
	}

	private func setupView() {
		illustrationImageView.isAccessibilityElement = true
		illustrationImageView.accessibilityLabel = BEAppStrings.BEMobileDataUsageSettings.description
		illustrationImageView.accessibilityIdentifier = BEAccessibilityIdentifiers.BEMobileDataUsageSettings.image
		titleLabel.text = BEAppStrings.BEMobileDataUsageSettings.title
		descriptionLabel.text = BEAppStrings.BEMobileDataUsageSettings.description
	}
}

extension MobileDataUsageSettingsViewController: UITableViewDataSource, UITableViewDelegate {
	func numberOfSections(in _: UITableView) -> Int {
		return 1
	}

	func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
			return UITableView.automaticDimension
		} else {
			return 38
		}
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 16
	}

	func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "mobileDataUsage", for: indexPath) as? MobileDataUsageTableViewCell else {
			fatalError("No cell for reuse identifier.")
		}

		cell.viewModel = MobileDataUsageViewModel(store)
		cell.configure()

		return cell
	}

	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		let isAccessibility = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
		return isAccessibility ? 120 : 44
	}
}
