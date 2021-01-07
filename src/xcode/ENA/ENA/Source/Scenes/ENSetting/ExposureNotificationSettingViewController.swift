// Corona-Warn-App
//
// SAP SE and all other contributors
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

import ExposureNotification
import UIKit

protocol ExposureNotificationSettingViewControllerDelegate: AnyObject {
	typealias Completion = (ExposureNotificationError?) -> Void

	func exposureNotificationSettingViewController(
		_ controller: ExposureNotificationSettingViewController,
		setExposureManagerEnabled enabled: Bool,
		then completion: @escaping Completion
	)
}

final class ExposureNotificationSettingViewController: UITableViewController {
	private weak var delegate: ExposureNotificationSettingViewControllerDelegate?

	private var lastActionCell: ActionCell?

	let model = ENSettingModel(content: [.banner, .actionCell, .euTracingCell, .actionDetailCell])
	let store: Store
	var enState: ENStateHandler.State

	init(
		initialEnState: ENStateHandler.State,
		store: Store,
		delegate: ExposureNotificationSettingViewControllerDelegate
	) {
		self.delegate = delegate
		self.store = store
		enState = initialEnState
		super.init(style: .grouped)
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .enaColor(for: .background)
		navigationItem.largeTitleDisplayMode = .always
		setUIText()
		tableView.sectionFooterHeight = 0.0
		tableView.separatorStyle = .none
		registerCells()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		tableView.reloadData()
	}

	private func setExposureManagerEnabled(
		_ enabled: Bool,
		then completion: @escaping ExposureNotificationSettingViewControllerDelegate.Completion
	) {
		delegate?.exposureNotificationSettingViewController(
			self,
			setExposureManagerEnabled: enabled,
			then: completion
		)
	}
	
	private func registerCells() {
		tableView.register(
			UINib(nibName: String(describing: TracingHistoryTableViewCell.self), bundle: nil),
			forCellReuseIdentifier: ReusableCellIdentifier.tracingCell.rawValue
		)

		tableView.register(
			UINib(nibName: String(describing: ImageTableViewCell.self), bundle: nil),
			forCellReuseIdentifier: ReusableCellIdentifier.banner.rawValue
		)

		tableView.register(
			UINib(nibName: String(describing: ActionDetailTableViewCell.self), bundle: nil),
			forCellReuseIdentifier: ReusableCellIdentifier.actionDetailCell.rawValue
		)

		tableView.register(
			UINib(nibName: String(describing: DescriptionTableViewCell.self), bundle: nil),
			forCellReuseIdentifier: ReusableCellIdentifier.descriptionCell.rawValue
		)

		tableView.register(
			UINib(nibName: String(describing: ActionTableViewCell.self), bundle: nil),
			forCellReuseIdentifier: ReusableCellIdentifier.actionCell.rawValue
		)

		tableView.register(
			UINib(nibName: String(describing: EuTracingTableViewCell.self), bundle: nil),
			forCellReuseIdentifier: ReusableCellIdentifier.euTracingCell.rawValue
		)
	}
}

extension ExposureNotificationSettingViewController {
	private func setUIText() {
		title = AppStrings.ExposureNotificationSetting.title
		navigationItem.title = AppStrings.ExposureNotificationSetting.title
	}

	private func handleEnableError(_ error: ExposureNotificationError, alert: Bool) {
		var errorMessage = ""
		switch error {
		case .exposureNotificationAuthorization:
			errorMessage = AppStrings.ExposureNotificationError.enAuthorizationError
		case .exposureNotificationRequired:
			errorMessage = AppStrings.ExposureNotificationError.enActivationRequiredError
		case .exposureNotificationUnavailable:
			errorMessage = AppStrings.ExposureNotificationError.enUnavailableError
		case .unknown(let message):
			errorMessage = AppStrings.ExposureNotificationError.enUnknownError + message
		case .apiMisuse:
			errorMessage = AppStrings.ExposureNotificationError.apiMisuse
		}
		if alert {
			alertError(message: errorMessage, title: AppStrings.ExposureNotificationError.generalErrorTitle)
		}
		logError(message: error.localizedDescription + " with message: " + errorMessage, level: .error)
		if let mySceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate {
			mySceneDelegate.requestUpdatedExposureState()
		}
		tableView.reloadData()
	}

	private func handleErrorIfNeed(_ error: ExposureNotificationError?) {
		if let error = error {
			handleEnableError(error, alert: true)
		} else {
			tableView.reloadData()
		}
	}

	private func silentErrorIfNeed(_ error: ExposureNotificationError?) {
		if let error = error {
			handleEnableError(error, alert: false)
		} else {
			tableView.reloadData()
		}
	}

	private func askConsentToUser() {
		self.persistForDPP(accepted: true)
		self.setExposureManagerEnabled(true, then: self.silentErrorIfNeed)
		
	}

	func persistForDPP(accepted: Bool) {
		self.store.exposureActivationConsentAccept = accepted
		self.store.exposureActivationConsentAcceptTimestamp = Int64(Date().timeIntervalSince1970)
	}
}

extension ExposureNotificationSettingViewController {
	override func numberOfSections(in _: UITableView) -> Int {
		model.content.count
	}

	override func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
		0
	}

	override func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		switch model.content[section] {
		case .actionCell:
			if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
				return UITableView.automaticDimension
			}
			return 40
		default:
			return 0
		}
	}

	override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch model.content[section] {
		case .actionCell:
			return AppStrings.ExposureNotificationSetting.actionCellHeader
		default:
			return nil
		}
	}

	override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
		1
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let section = indexPath.section
		let content = model.content[section]

		guard content.cellType == .euTracingCell else { return }

		let vc = BEEUSettingsViewController()
		navigationController?.pushViewController(vc, animated: true)
	}

	override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let section = indexPath.section
		let content = model.content[section]
		if let cell = tableView.dequeueReusableCell(withIdentifier: content.cellType.rawValue, for: indexPath) as? ConfigurableENSettingCell {
			switch content {
			case .banner:
				cell.configure(for: enState)
			case .actionCell:
				if let lastActionCell = lastActionCell {
					return lastActionCell
				}
				if let cell = cell as? ActionCell {
					cell.configure(for: enState, delegate: self)
					lastActionCell = cell
				}
			case .euTracingCell:
				return euTracingCell(for: indexPath, in: tableView)

			case .tracingCell, .actionDetailCell:
				switch enState {
				case .enabled, .disabled:
					let tracingCell = tableView.dequeueReusableCell(withIdentifier: ENSettingModel.Content.tracingCell.cellType.rawValue, for: indexPath)
					if let tracingCell = tracingCell as? TracingHistoryTableViewCell {
						let colorConfig: (UIColor, UIColor) = (self.enState == .enabled) ?
							(UIColor.enaColor(for: .tint), UIColor.enaColor(for: .hairline)) :
							(UIColor.enaColor(for: .textPrimary2), UIColor.enaColor(for: .hairline))
						let activeTracing = store.tracingStatusHistory.activeTracing()
						let text = [
							activeTracing.exposureDetectionActiveTracingSectionTextParagraph0,
							activeTracing.exposureDetectionActiveTracingSectionTextParagraph1]
							.joined(separator: "\n\n")

						let numberOfDaysWithActiveTracing = activeTracing.inDays
						let title = NSLocalizedString("ExposureDetection_ActiveTracingSection_Title", comment: "")
						let subtitle = NSLocalizedString("ExposureDetection_ActiveTracingSection_Subtitle", comment: "")

						tracingCell.configure(
							progress: CGFloat(numberOfDaysWithActiveTracing),
							title: title,
							subtitle: subtitle,
							text: text,
							colorConfigurationTuple: colorConfig
						)
						return tracingCell
					}
				case .bluetoothOff, .restricted, .notAuthorized, .unknown:
					if let cell = cell as? ActionCell {
						cell.configure(for: enState, delegate: self)
					}
				}
			case .descriptionCell:
				cell.configure(for: enState)
			}
			return cell
		} else {
			return UITableViewCell()
		}
	}
	
	private func euTracingCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
		let dequeuedEUTracingCell = tableView.dequeueReusableCell(withIdentifier: ENSettingModel.Content.euTracingCell.cellType.rawValue, for: indexPath)
		guard let euTracingCell = dequeuedEUTracingCell as? EuTracingTableViewCell else {
			return UITableViewCell()
		}

		euTracingCell.configure()
		return euTracingCell
	}
}

extension ExposureNotificationSettingViewController: ActionTableViewCellDelegate {
	func performAction(action: SettingAction) {
		switch action {
		case .enable(true):
			setExposureManagerEnabled(true, then: handleErrorIfNeed)
		case .enable(false):
			setExposureManagerEnabled(false, then: handleErrorIfNeed)
		case .askConsent:
			askConsentToUser()
		}
	}
}

extension ExposureNotificationSettingViewController {
	fileprivate enum ReusableCellIdentifier: String {
		case banner
		case actionCell
		case euTracingCell
		case tracingCell
		case actionDetailCell
		case descriptionCell
	}
}

private extension ENSettingModel.Content {
	var cellType: ExposureNotificationSettingViewController.ReusableCellIdentifier {
		switch self {
		case .banner:
			return .banner
		case .actionCell:
			return .actionCell
		case .euTracingCell:
			return .euTracingCell
		case .tracingCell:
			return .tracingCell
		case .actionDetailCell:
			return .actionDetailCell
		case .descriptionCell:
			return .descriptionCell
		}
	}
}

// MARK: ENStateHandler Updating
extension ExposureNotificationSettingViewController: ENStateHandlerUpdating {
	func updateEnState(_ enState: ENStateHandler.State) {
		log(message: "Get the new state: \(enState)")
		self.enState = enState
		lastActionCell?.configure(for: enState, delegate: self)
		self.tableView.reloadData()
	}
}
