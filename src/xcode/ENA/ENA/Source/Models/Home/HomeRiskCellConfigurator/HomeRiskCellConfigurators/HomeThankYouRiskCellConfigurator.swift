//
// Corona-Warn-App
//
// SAP SE and all other contributors /
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
//

import UIKit

final class HomeThankYouRiskCellConfigurator: HomeRiskCellConfigurator {
	
	// MARK: Configuration

	func configure(cell: RiskThankYouCollectionViewCell) {
		
		// we no longer support the thank you cell since we reset the app
	}

	func setupAccessibility(_ cell: RiskThankYouCollectionViewCell) {
		cell.titleLabel.isAccessibilityElement = true
		cell.viewContainer.isAccessibilityElement = false
		cell.stackView.isAccessibilityElement = false
		cell.bodyLabel.isAccessibilityElement = true

		cell.titleLabel.accessibilityTraits = .header
	}

	// MARK: Hashable

	func hash(into hasher: inout Swift.Hasher) {
		// this class has no stored properties, that's why hash function is empty here
	}

	static func == (lhs: HomeThankYouRiskCellConfigurator, rhs: HomeThankYouRiskCellConfigurator) -> Bool {
		// instances of this class have no differences between each other
		true
	}
}
