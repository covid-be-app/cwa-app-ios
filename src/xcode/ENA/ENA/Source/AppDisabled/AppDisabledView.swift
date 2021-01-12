////
// 🦠 Corona-Warn-App
//

import UIKit

class AppDisabledView: UIView {

	// MARK: - Init

	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}
	
	
	let textLabel: ENALabel = {
		let label = ENALabel()
		label.numberOfLines = 0
		label.textAlignment = .center
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()
	
	func setup() {
		backgroundColor = ColorCompatibility.systemBackground
		
		addSubview(textLabel)
		
		NSLayoutConstraint.activate([
			textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
			textLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
			textLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 30)
		])
	}
}
