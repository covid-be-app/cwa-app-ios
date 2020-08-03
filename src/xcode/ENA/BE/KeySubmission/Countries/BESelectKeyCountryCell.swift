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
import ExposureNotification

class BESelectKeyCountryCell: UITableViewCell {

	var key:ENTemporaryExposureKey!
	var country:BECountry!
	
	lazy var title = ENALabel(frame: .zero)
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

		// MARK: - Title adjustment.
		title.style = .headline
		title.textColor = .enaColor(for: .textPrimary1)
		title.lineBreakMode = .byWordWrapping
		title.numberOfLines = 0

		// MARK: - Body adjustment.
		body.style = .body
		body.textColor = .enaColor(for: .textPrimary1)
		body.lineBreakMode = .byWordWrapping
		body.numberOfLines = 0

		UIView.translatesAutoresizingMaskIntoConstraints(for: [
			title, body
		], to: false)

		contentView.addSubviews([title,body])
	}

	private func setupConstraints() {
		body.sizeToFit()
		title.sizeToFit()

		title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
		title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
		title.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true

		body.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
		body.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
		body.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
	}

	func configure(key:ENTemporaryExposureKey,country:BECountry) {
		setup()
		setupConstraints()
		self.key = key
		self.country = country

		let date = key.rollingStartNumber.date
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none

		self.title.text = dateFormatter.string(from: date)
		self.body.text = country.localizedName
	}
}
