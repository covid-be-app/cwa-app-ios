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

protocol HomeRiskLevelTableViewCellDelegate: AnyObject {
	func actionButtonTapped(cell: HomeRiskLevelTableViewCell)
}

class HomeRiskLevelTableViewCell: HomeCardTableViewCell {
	// MARK: Properties

	var delegate: HomeRiskLevelTableViewCellDelegate?

	// MARK: Outlets

	@IBOutlet var titleLabel: ENALabel!
	@IBOutlet var chevronImageView: UIImageView!
	@IBOutlet var bodyLabel: ENALabel!
	@IBOutlet var actionButton: ENAButton!

	@IBOutlet var topContainer: UIStackView!
	@IBOutlet var stackView: UIStackView!
	@IBOutlet var riskViewStackView: UIStackView!

	// MARK: Nib Loading

	// Ignore touches on the button when it's disabled
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let buttonPoint = convert(point, to: actionButton)
		let containsPoint = actionButton.bounds.contains(buttonPoint)
		if containsPoint, !actionButton.isEnabled {
			return nil
		}
		return super.hitTest(point, with: event)
	}

	// MARK: Actions

	@IBAction func actionButtonTapped(_: UIButton) {
		delegate?.actionButtonTapped(cell: self)
	}

	// MARK: Configuring the UI

	func configureTitle(title: String, titleColor: UIColor) {
		titleLabel.text = title
		titleLabel.textColor = titleColor
	}

	func configureBody(text: String, bodyColor: UIColor, isHidden: Bool) {
		bodyLabel.text = text
		bodyLabel.textColor = bodyColor
		bodyLabel.isHidden = isHidden
	}

	func configureBackgroundColor(color: UIColor) {
		viewContainer.backgroundColor = color
	}

	func configureActionButton(title: String, isEnabled: Bool, isHidden: Bool) {
		actionButton.setTitle(title, for: .normal)
		actionButton.isEnabled = isEnabled
		actionButton.isHidden = isHidden
		actionButton.isAccessibilityElement = true
		actionButton.accessibilityLabel = title
	}

	func configureDetectionIntervalLabel(text: String, isHidden: Bool) {
		return
	}

	func configureRiskViews(cellConfigurators: [HomeRiskViewConfiguratorAny]) {

		riskViewStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

		for itemConfigurator in cellConfigurators {
			let nibName = itemConfigurator.viewAnyType.stringName()
			let nib = UINib(nibName: nibName, bundle: .main)
			if let riskView = nib.instantiate(withOwner: self, options: nil).first as? UIView {
				riskViewStackView.addArrangedSubview(riskView)
				itemConfigurator.configureAny(riskView: riskView)
			}
		}
	
		if let riskItemView = riskViewStackView.arrangedSubviews.last as? RiskItemViewSeparatorable {
			riskItemView.hideSeparator()
		}

		riskViewStackView.isHidden = cellConfigurators.isEmpty
	}
	
}
