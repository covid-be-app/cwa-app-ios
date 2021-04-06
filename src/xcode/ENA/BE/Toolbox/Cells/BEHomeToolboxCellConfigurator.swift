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

class BEHomeToolboxCellConfigurator: TableViewCellConfigurator {

	init() {
	}
	
	func configure(cell: BEToolboxTableViewCell) {
		cell.configure(title: BEAppStrings.BEHome.toolboxTitle, description: BEAppStrings.BEHome.toolboxDescription, image: UIImage(named:"Illu_Home_Toolbox"), accessibilityIdentifier: BEAccessibilityIdentifiers.BEHome.toolbox)
	}
	
	// MARK: Hashable

	func hash(into hasher: inout Swift.Hasher) {
		hasher.combine("toolbox")
	}

	static func == (lhs: BEHomeToolboxCellConfigurator, rhs: BEHomeToolboxCellConfigurator) -> Bool {
		return true
	}
}
