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

class BENewsTableViewCellConfigurator: TableViewCellConfigurator {
	let service = BEDynamicNewsTextService()

	init() {
	}
	
	func configure(cell: BENewsTableViewCell) {
		
		cell.titleLabel.text = service.newsTitle()
		cell.descriptionLabel.text = service.newsText()
	}
	
	// MARK: Hashable

	func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(service.newsText())
		hasher.combine(service.newsTitle())
	}

	static func == (lhs: BENewsTableViewCellConfigurator, rhs: BENewsTableViewCellConfigurator) -> Bool {
		return lhs.service.newsTitle() == rhs.service.newsTitle() && lhs.service.newsText() == rhs.service.newsText()
	}
}
