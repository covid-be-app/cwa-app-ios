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


extension BEToolboxItem {
	var viewController: UIViewController {
		let vc = BEToolboxItemViewController(configuration!)
		
		return vc
	}
}

class BEToolboxItemViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var imageView: UIImageView!

	private let configuration: BEToolboxItem.DetailViewControllerConfiguration
	
	init(_ configuration: BEToolboxItem.DetailViewControllerConfiguration) {
		self.configuration = configuration
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - View life cycle methods.

	override func viewDidLoad() {
		super.viewDidLoad()
		self.setupBackButton()
		navigationItem.largeTitleDisplayMode = .always
		navigationItem.title = configuration.title
		tableView.backgroundColor = .enaColor(for: .separator)
		tableView.register(UINib(nibName: "BEToolboxItemCell", bundle: nil), forCellReuseIdentifier: BEToolboxItemCell.cellIdentifier)
		tableView.rowHeight = UITableView.automaticDimension

		imageView.image = configuration.icon
		imageView.accessibilityIdentifier = configuration.accessibilityIdentifier
	}
}

extension BEToolboxItemViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return configuration.links.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let link = configuration.links[indexPath.row]
		
		guard let cell = tableView.dequeueReusableCell(withIdentifier: BEToolboxItemCell.cellIdentifier, for: indexPath) as? BEToolboxItemCell else {
			fatalError("")
		}
		
		cell.isAccessibilityElement = true
		cell.configure(text: link.text, suffix: link.suffix)

		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let link = configuration.links[indexPath.row]

		UIApplication.shared.open(link.url, options: [:], completionHandler: nil)
	}
}
