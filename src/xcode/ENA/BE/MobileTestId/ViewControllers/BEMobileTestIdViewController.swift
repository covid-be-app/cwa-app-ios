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

protocol BEMobileTestIdViewControllerDelegate : class {
	func mobileTestIdViewController(_ vc:BEMobileTestIdViewController, finshedWithMobileTestId mobileTestId:BEMobileTestId )
}

class BEMobileTestIdViewController: UIViewController {

	@IBOutlet weak var enterDateExplanationLabel:ENALabel!
	
	@IBOutlet weak var selectDateStepView:UIView!
	@IBOutlet weak var generatedCodeStepView:UIView!
	
	@IBOutlet weak var datePicker:UIDatePicker!
	
	@IBOutlet var selectDateView:UIView!
	@IBOutlet weak var selectButton:UIButton!

	
	@IBOutlet weak var dateLabel:UILabel!
	@IBOutlet weak var codeLabel:UILabel!
	@IBOutlet weak var qrCodeImageView:UIImageView!
	@IBOutlet weak var saveButton:UIButton!
	@IBOutlet weak var saveExplanationLabel:UILabel!
	
	weak var delegate:BEMobileTestIdViewControllerDelegate?
	
	private var overlayView = UIView()
	
	private var selectedDate:Date! {
		didSet {
			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .none
			selectDateStepView.isHidden = true
			generatedCodeStepView.isHidden = false
			removeDatePicker()
			dateLabel.text = dateFormatter.string(from: selectedDate)
			mobileTestId = BEMobileTestId(datePatientInfectious: String.fromDateWithoutTime(date:selectedDate))
		}
	}
	
	private var mobileTestId:BEMobileTestId! {
		didSet {
			updateTestIdGUI()
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

		setupDateInfo()
		setupSaveInfo()
		
		generatedCodeStepView.isHidden = true
		
		overlayView.translatesAutoresizingMaskIntoConstraints = false
		overlayView.backgroundColor = UIColor.black
		overlayView.alpha = 0.15

		selectButton.accessibilityIdentifier = BEAccessibilityIdentifiers.BEMobileTestId.selectDate
		saveButton.accessibilityIdentifier = BEAccessibilityIdentifiers.BEMobileTestId.save
		
		setupTitle()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		startSelectingDate(animated)
	}
	
	private func setupDateInfo() {
		// we allow to choose a date that's up to 2 months before today
		let minimumTimeInterval = TimeInterval(-2*31*24*60*60)

		enterDateExplanationLabel.text = BEAppStrings.BEMobileTestId.dateExplanation
		
		selectButton.setTitle(BEAppStrings.BEMobileTestId.select, for: .normal)
		datePicker.maximumDate = Date()
		datePicker.minimumDate = Date(timeInterval: minimumTimeInterval, since: datePicker.maximumDate!)
	}

	
	private func setupTitle() {
		navigationItem.largeTitleDisplayMode = .always
		title = BEAppStrings.BEMobileTestId.title
	}
	
	private func setupSaveInfo() {
		saveButton.setTitle(BEAppStrings.BEMobileTestId.save, for: .normal)
		saveExplanationLabel.text = BEAppStrings.BEMobileTestId.saveExplanation
	}
	
	private func startSelectingDate(_ animated:Bool) {
		selectDateView.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(overlayView)
		overlayView.bottomAnchor.constraint(equalTo:self.navigationController!.view.bottomAnchor).isActive = true
		overlayView.leftAnchor.constraint(equalTo:self.navigationController!.view.leftAnchor).isActive = true
		overlayView.rightAnchor.constraint(equalTo:self.navigationController!.view.rightAnchor).isActive = true
		overlayView.topAnchor.constraint(equalTo:self.navigationController!.view.topAnchor).isActive = true
		self.view.addSubview(selectDateView)
		self.view.bottomAnchor.constraint(equalTo: selectDateView.bottomAnchor).isActive = true
		self.view.leftAnchor.constraint(equalTo: selectDateView.leftAnchor).isActive = true
		self.view.rightAnchor.constraint(equalTo: selectDateView.rightAnchor).isActive = true
		
		if(animated) {
			let oldOpacity = overlayView.alpha
			overlayView.alpha = 0
			selectDateView.transform = CGAffineTransform(translationX: 0, y: selectDateView.bounds.size.height * 1.5)

			UIView.animate(withDuration: 0.2) {
				self.overlayView.alpha = oldOpacity
				self.selectDateView.transform = .identity
			}
		}
	}
	
	@IBAction func selectDatePressed() {
		selectedDate = datePicker.date
	}
	
	private func removeDatePicker() {
		let oldOpacity = overlayView.alpha
		
		UIView.animate(withDuration: 0.2, animations: {
			self.overlayView.alpha = 0
			self.selectDateView.transform = CGAffineTransform(translationX: 0, y: self.selectDateView.bounds.size.height * 1.5)
		}) { _ in
			self.overlayView.alpha = oldOpacity
			self.overlayView.removeFromSuperview()
			self.selectDateView.transform = .identity
			self.selectDateView.removeFromSuperview()
		}
	}
	
	private func updateTestIdGUI() {
		let qrCodeImage = UIImage.generateQRCode(mobileTestId.fullString, size: qrCodeImageView.bounds.size.width * self.view.contentScaleFactor)
		
		qrCodeImageView.image = qrCodeImage
		codeLabel.text = mobileTestId.fullString
	}
	
	@IBAction func savePressed() {
		delegate?.mobileTestIdViewController(self, finshedWithMobileTestId: mobileTestId)
	}
}
