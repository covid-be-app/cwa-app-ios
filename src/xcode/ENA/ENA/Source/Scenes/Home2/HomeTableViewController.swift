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

protocol HomeViewControllerDelegate: AnyObject {
	func showRiskLegend()
	func showExposureNotificationSetting(enState: ENStateHandler.State)
	func showExposureDetection(state: HomeInteractor.State, isRequestRiskRunning: Bool)
	func setExposureDetectionState(state: HomeInteractor.State, isRequestRiskRunning: Bool)
	func showExposureSubmission(with result: TestResult?)
	func showInviteFriends()
	func showWebPage(from viewController: UIViewController, urlString: String)
	func showAppInformation()
	func showSettings(enState: ENStateHandler.State)
	func addToEnStateUpdateList(_ anyObject: AnyObject?)
}

class HomeTableViewController: UITableViewController, RequiresAppDependencies {

	enum CellType: String {
		case activate = "activate"
	}
	
	var sections: HomeInteractor.SectionConfiguration = []

	
	private var homeInteractor: HomeInteractor!

	private weak var delegate: HomeViewControllerDelegate?

	enum Section: Int {
		case actions
		case infos
	}

	init(
		delegate: HomeViewControllerDelegate,
		detectionMode: DetectionMode,
		exposureManagerState: ExposureManagerState,
		initialEnState: ENStateHandler.State,
		risk: Risk?,
		exposureSubmissionService: ExposureSubmissionService,
		statisticsService: BEStatisticsService
	) {
		self.delegate = delegate

		super.init(style: .plain)

		self.homeInteractor = HomeInteractor(
			homeViewController: self,
			state: .init(
				detectionMode: detectionMode,
				exposureManagerState: exposureManagerState,
				enState: initialEnState,
				risk: risk
			),
			exposureSubmissionService: exposureSubmissionService,
			statisticsService: statisticsService
		)
		navigationItem.largeTitleDisplayMode = .never
		delegate.addToEnStateUpdateList(homeInteractor)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		// :BE: disable background fetch alert as tests have shown it has no influence on the covid exposure checks
		
		setupBarButtonItems()
		setupAccessibility()

		homeInteractor.buildSections()
		updateSections()
		tableView.reloadData()

		setStateOfChildViewControllers()
		
		// :BE: show env label if not production
		#if !UITESTING
			showEnvironmentLabel()
		#endif
	}
	
	func reloadData() {
		tableView.reloadData()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		homeInteractor.updateTestResults()
		homeInteractor.requestRisk(userInitiated: false)
		homeInteractor.requestInfectionSummary()
		updateBackgroundColor()
	}
	
	func updateSections() {
		sections = homeInteractor.sections
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		guard store.userNeedsToBeInformedAboutHowRiskDetectionWorks else {
			return
		}
		// TODO: Check whether or not we have to display some kind of different alert (eg. the forced update alert).
		let alert = UIAlertController.localizedHowRiskDetectionWorksAlertController(
			maximumNumberOfDays: TracingStatusHistory.maxStoredDays
		)
		present(alert, animated: true) {
			self.store.userNeedsToBeInformedAboutHowRiskDetectionWorks = false
		}
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		updateBackgroundColor()
	}

	private func setupBarButtonItems() {
		navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Corona-Warn-App"), style: .plain, target: nil, action: nil)

		let infoButton = UIButton(type: .infoLight)
		infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
		navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
	}

	/// This method sets up a background fetch alert, and presents it, if needed.
	/// Check the `createBackgroundFetchAlert` method for more information.
	private func setupBackgroundFetchAlert() {
		guard let alert = Self.createBackgroundFetchAlert(
			status: UIApplication.shared.backgroundRefreshStatus,
			inLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
			hasSeenAlertBefore: homeInteractor.store.hasSeenBackgroundFetchAlert,
			store: homeInteractor.store
			) else { return }

		self.present(
			alert,
			animated: true,
			completion: nil
		)
	}

	private func setupAccessibility() {
		navigationItem.leftBarButtonItem?.customView = UIImageView(image: navigationItem.leftBarButtonItem?.image)
		navigationItem.leftBarButtonItem?.isAccessibilityElement = true
		navigationItem.leftBarButtonItem?.accessibilityTraits = .none
		navigationItem.leftBarButtonItem?.accessibilityLabel = AppStrings.Home.leftBarButtonDescription
		navigationItem.leftBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.Home.leftBarButtonDescription
		navigationItem.rightBarButtonItem?.isAccessibilityElement = true
		navigationItem.rightBarButtonItem?.accessibilityLabel = AppStrings.Home.rightBarButtonDescription
		navigationItem.rightBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.Home.rightBarButtonDescription
	}
	
	@IBAction private func infoButtonTapped() {
		delegate?.showRiskLegend()
	}

	func setStateOfChildViewControllers() {
		delegate?.setExposureDetectionState(state: homeInteractor.state, isRequestRiskRunning: homeInteractor.riskProvider.isLoading)
	}

	func updateState(detectionMode: DetectionMode, exposureManagerState: ExposureManagerState, risk: Risk?) {
		homeInteractor.state.detectionMode = detectionMode
		homeInteractor.state.exposureManagerState = exposureManagerState
		homeInteractor.state.risk = risk

		tableView.reloadData()
	}

	func showExposureSubmissionWithoutResult() {
		showExposureSubmission()
	}

	func showExposureSubmission(with result: TestResult? = nil) {
		delegate?.showExposureSubmission(with: result)
	}

	func showExposureNotificationSetting() {
		delegate?.showExposureNotificationSetting(enState: self.homeInteractor.state.enState)
	}

	func showExposureDetection() {
		delegate?.showExposureDetection(state: homeInteractor.state, isRequestRiskRunning: homeInteractor.riskProvider.isLoading)
	}

	private func showEnvironmentLabel() {
		if BEEnvironment.current != .production {
			let label = UILabel(frame: .zero)
			label.translatesAutoresizingMaskIntoConstraints = false
			label.textColor = .red
			label.font = .systemFont(ofSize: 16)
			label.text = "ENVIRONMENT: \(BEEnvironment.current.rawValue)"
			self.view.addSubview(label)
			self.view.topAnchor.constraint(equalTo: label.topAnchor, constant: 16).isActive = true
			self.view.centerXAnchor.constraint(equalTo: label.centerXAnchor).isActive = true
			self.view.bringSubviewToFront(label)
		}
	}
	
	private func updateBackgroundColor() {
		if traitCollection.userInterfaceStyle == .light {
			tableView.backgroundColor = .enaColor(for: .background)
		} else {
			tableView.backgroundColor = .enaColor(for: .separator)
		}
	}

	private func configureTableView() {
		self.tableView.separatorStyle = .none

		self.tableView.register(UINib(nibName: String(describing: HomeActivateCell.self), bundle: nil), forCellReuseIdentifier: CellType.activate.rawValue)
	}
	
	func reloadCell(at indexPath: IndexPath) {
		guard let cell = tableView.cellForRow(at: indexPath) else { return }
		
		// :TODO:
		//sections[indexPath.section].cellConfigurators[indexPath.item].configureAny(cell: cell)
		
		tableView.reloadRows(at: [indexPath], with: .automatic)
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
		return homeInteractor.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let section = homeInteractor.sections[section]

		return section.cellConfigurators.count
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

}

// MARK: - Update test state.

extension HomeTableViewController {
	func showTestResultScreen() {
		showExposureSubmission(with: homeInteractor.testResult)
	}

	func updateTestResultState() {
		homeInteractor.reloadActionSection()
		homeInteractor.updateTestResults()
	}
}

extension HomeTableViewController: ExposureStateUpdating {
	func updateExposureState(_ state: ExposureManagerState) {
		homeInteractor.state.exposureManagerState = state
		tableView.reloadData()
	}
}

extension HomeTableViewController: ENStateHandlerUpdating {
	func updateEnState(_ state: ENStateHandler.State) {
		homeInteractor.state.enState = state
		tableView.reloadData()
	}
}

extension HomeTableViewController: NavigationBarOpacityDelegate {
	var preferredNavigationBarOpacity: CGFloat {
		let alpha = (tableView.adjustedContentInset.top + tableView.contentOffset.y) / tableView.contentInset.top
		return max(0, min(alpha, 1))
	}
}
