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

class BESelectCountryCell: UITableViewCell {

	var country:BECountry!

	lazy var body = ENALabel(frame: .zero)

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
	}

	override func awakeFromNib() {
		super.awakeFromNib()
		self.autoresizingMask = .flexibleHeight
	}

	private func setup() {

		// MARK: - General cell setup.
		selectionStyle = .none
		backgroundColor = .enaColor(for: .background)

		// MARK: - Body adjustment.
		body.style = .body
		body.textColor = .enaColor(for: .textPrimary1)
		body.lineBreakMode = .byWordWrapping
		body.numberOfLines = 0

		UIView.translatesAutoresizingMaskIntoConstraints(for: [
			body
		], to: false)

		contentView.addSubviews([body])
		
		self.selectionStyle = .gray
	}

	private func setupConstraints() {
		body.sizeToFit()

		body.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
		body.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
		body.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
	}

	func configure(country:BECountry) {
		setup()
		setupConstraints()
		self.country = country
		self.body.text = country.localizedName
	}
	
}
