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

class HomeCardTableViewCell: UITableViewCell {

	@IBOutlet var viewContainer: UIView!

	private let cornerRadius: CGFloat = 14.0

	override func awakeFromNib() {
		super.awakeFromNib()
		self.selectionStyle = .none

		clipsToBounds = false
		contentView.clipsToBounds = false
		self.contentView.backgroundColor = .enaColor(for: .separator)
		
		if let container = viewContainer {
			container.backgroundColor = .enaColor(for: .background)
			container.clipsToBounds = true
			container.layer.cornerRadius = cornerRadius

			container.layer.shadowColor = UIColor.enaColor(for: .shadow).cgColor
			container.layer.shadowOffset = .init(width: 0.0, height: 10.0)
			container.layer.shadowRadius = 36.0
			container.layer.shadowOpacity = 1
			
			container.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
		}
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		if let container = viewContainer {
			container.layer.shadowColor = UIColor.enaColor(for: .shadow).cgColor
		}
	}
}
