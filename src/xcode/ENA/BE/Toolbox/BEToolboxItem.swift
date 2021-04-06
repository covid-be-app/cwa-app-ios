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

import Foundation
import UIKit

struct BEToolboxItem {

	struct DetailLink {
		let text: String
		let suffix: String?
		let url: URL
	}

	struct DetailViewControllerConfiguration {
		let title: String
		let icon: UIImage
		let accessibilityIdentifier: String
		let links: [DetailLink]
		
		init(title: String, icon: String, accessibilityIdentifier: String, links: [DetailLink]) {
			self.title = title
			self.icon = UIImage(named: icon)!
			self.accessibilityIdentifier = accessibilityIdentifier
			self.links = links
		}
	}

	let text: String
	let icon: UIImage
	let accessibilityIdentifier: String
	let configuration: DetailViewControllerConfiguration

	init(text: String, icon: String, accessibilityIdentifier: String, configuration: DetailViewControllerConfiguration) {
		self.text = text
		self.icon = UIImage(named: icon)!
		self.accessibilityIdentifier = accessibilityIdentifier
		self.configuration = configuration
	}
}
