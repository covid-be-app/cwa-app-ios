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
	func showToolbox()
	func showAlreadyDidTestScreen()
	func showWebPage(from viewController: UIViewController, urlString: String)
	func showAppInformation()
	func showSettings(enState: ENStateHandler.State)
	func addToEnStateUpdateList(_ anyObject: AnyObject?)
}

class HomeTableViewController: UIViewController, RequiresAppDependencies {

	enum CellType: String {
		case activate = "activate"
		case infectionSummary = "infectionSummary"
		case toolbox = "toolbox"
		case riskLevel = "riskLevel"
		case info = "info"
		case testResult = "testResult"
		case riskInactive = "riskInactive"
		case riskFindingPositive = "riskFindingPositive"
		case testResultLoading = "testResultLoading"
	}
	
	var sections: HomeInteractor.SectionConfiguration = [] {
		didSet {
			reloadData()
		}
	}

	private var tableViewSectionHashes: [[Int]] = []
	
	private var homeInteractor: HomeInteractor!
	private var tableView = UITableView()
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
		super.init(nibName: nil, bundle: nil)

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
		self.view.addSubview(tableView)
		tableView.translatesAutoresizingMaskIntoConstraints = false
		view.leftAnchor.constraint(equalTo: tableView.leftAnchor).isActive = true
		view.rightAnchor.constraint(equalTo: tableView.rightAnchor).isActive = true
		view.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
		view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true

		configureTableView()
		
		setupBarButtonItems()
		setupAccessibility()

		homeInteractor.buildSections()
		updateSections()
		reloadData()

		setStateOfChildViewControllers()
		
		// :BE: show env label if not production
		#if !UITESTING
			showEnvironmentLabel()
		#endif
	}
	
	func reloadData() {
		
		// avoid tableview update warning
		if self.view.superview == nil {
			return
		}
		
		if sections.count != tableViewSectionHashes.count {
			fullReload()
			return
		}
		
		sections.enumerated().forEach { sectionIndex, section in
			let hashes = tableViewSectionHashes[sectionIndex]
			
			if hashes.count != section.cellConfigurators.count {
				reloadSection(sectionIndex)
			} else {
				var rowsToReload: [Int] = []
				
				// we need to reconfigure unchanged rows
				// because some cell configurators apparently latch on the cell as delegate
				// and when they are replaced here of course the delegate becomes nil
				var rowsToReconfigure: [Int] = []

				hashes.enumerated().forEach { rowIndex, hash in
					let configurator = section.cellConfigurators[rowIndex]
					let newHash = configurator.hash
				
					if newHash != hash {
						rowsToReload.append(rowIndex)
					} else {
						rowsToReconfigure.append(rowIndex)
					}
				}
				
				if !rowsToReload.isEmpty {
					reloadRows(rowsToReload, in: sectionIndex)
				}
				
				if !rowsToReconfigure.isEmpty {
					reconfigureRows(rowsToReconfigure, in: sectionIndex)
				}
			}
		}
	}
	
	private func fullReload() {
		tableViewSectionHashes = sections.map { section in
			return section.cellConfigurators.map { $0.hash }
		}
		
		tableView.reloadData()
	}

	private func reloadSection(_ index: Int) {
		tableViewSectionHashes[index] = sections[index].cellConfigurators.map { $0.hash }

		tableView.reloadSections(IndexSet([index]), with: .automatic)
	}
	
	private func reloadRows(_ rows: [Int], in section: Int) {
		tableViewSectionHashes[section] = sections[section].cellConfigurators.map { $0.hash }
		let indexPaths = rows.map { IndexPath(row: $0, section: section) }
		tableView.reloadRows(at: indexPaths, with: .automatic)
	}

	private func reconfigureRows(_ rows: [Int], in section: Int) {
		let configurators = sections[section].cellConfigurators
		rows.forEach { row in
			let configurator = configurators[row]
			if let cell = tableView.cellForRow(at: IndexPath(row: row, section: section)) {
				configurator.configureAny(cell: cell)
			}
		}
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
		reloadData()
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

		reloadData()
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
	
	func showToolbox() {
		delegate?.showToolbox()
	}

	func showExposureDetection() {
		delegate?.showExposureDetection(state: homeInteractor.state, isRequestRiskRunning: homeInteractor.riskProvider.isLoading)
	}
	
	func cellForRow(at indexPath: IndexPath) -> UITableViewCell? {
		return tableView.cellForRow(at: indexPath)
	}

	private func showEnvironmentLabel() {
		if BEEnvironment.current != .production {
			let label = UILabel(frame: .zero)
			label.translatesAutoresizingMaskIntoConstraints = false
			label.textColor = .red
			label.font = .systemFont(ofSize: 16)
			label.text = "ENVIRONMENT: \(BEEnvironment.current.rawValue)"
			self.tableView.addSubview(label)
			self.tableView.topAnchor.constraint(equalTo: label.topAnchor, constant: 0).isActive = true
			self.tableView.centerXAnchor.constraint(equalTo: label.centerXAnchor).isActive = true
			self.tableView.bringSubviewToFront(label)
		}
	}
	
	private func updateBackgroundColor() {
		tableView.backgroundColor = .enaColor(for: .separator)
	}

	private func configureTableView() {
		tableView.separatorStyle = .none
		tableView.delegate = self
		tableView.dataSource = self
		
		tableView.register(UINib(nibName: HomeActivateCell.stringName(), bundle: nil), forCellReuseIdentifier: HomeActivateCell.stringName())
		tableView.register(UINib(nibName: HomeRiskLevelTableViewCell.stringName(), bundle: nil), forCellReuseIdentifier: HomeRiskLevelTableViewCell.stringName())
		tableView.register(UINib(nibName: HomeInfoCell.stringName(), bundle: nil), forCellReuseIdentifier: HomeInfoCell.stringName())
		tableView.register(UINib(nibName: HomeTestResultTableViewCell.stringName(), bundle: nil), forCellReuseIdentifier: HomeTestResultTableViewCell.stringName())
		tableView.register(UINib(nibName: HomeRiskInactiveTableViewCell.stringName(), bundle: nil), forCellReuseIdentifier: HomeRiskInactiveTableViewCell.stringName())
		tableView.register(UINib(nibName: HomeRiskFindingPositiveTableViewCell.stringName(), bundle: nil), forCellReuseIdentifier: HomeRiskFindingPositiveTableViewCell.stringName())
		tableView.register(UINib(nibName: HomeTestResultLoadingTableViewCell.stringName(), bundle: nil), forCellReuseIdentifier: HomeTestResultLoadingTableViewCell.stringName())
		tableView.register(UINib(nibName: BEInfectionSummaryTableViewCell.stringName(), bundle: nil), forCellReuseIdentifier: BEInfectionSummaryTableViewCell.stringName())
		tableView.register(UINib(nibName: BEToolboxTableViewCell.stringName(), bundle: nil), forCellReuseIdentifier: BEToolboxTableViewCell.stringName())
		tableView.register(UINib(nibName: HomeSpacerCell.stringName(), bundle: nil), forCellReuseIdentifier: HomeSpacerCell.stringName())
	}
	
	private func showScreenForActionSectionForCell(at indexPath: IndexPath) {
		let cell = tableView.cellForRow(at: indexPath)
		switch cell {
		case is HomeActivateCell:
			showExposureNotificationSetting()
		case is BEToolboxTableViewCell:
			showToolbox()
		case is HomeRiskLevelTableViewCell:
			showExposureDetection()
		case is HomeRiskFindingPositiveTableViewCell:
			showExposureSubmission(with: homeInteractor.testResult)
		case is HomeTestResultTableViewCell:
			if homeInteractor.testResult != nil {
				showExposureSubmission(with: homeInteractor.testResult)
			}
		case is HomeRiskInactiveTableViewCell:
			showExposureDetection()
		default:
			return
		}
	}

	private func showScreen(at indexPath: IndexPath) {
		guard let section = Section(rawValue: indexPath.section) else { return }
		let row = indexPath.row
		switch section {
		case .actions:
			showScreenForActionSectionForCell(at: indexPath)
		case .infos:
			switch row {
			case 0:
				delegate?.showInviteFriends()
			case 1:
				delegate?.showWebPage(from: self, urlString: AppStrings.SafariView.targetURL)
			case 2:
				delegate?.showAppInformation()
			case 3:
				delegate?.showSettings(enState: self.homeInteractor.state.enState)
			default:
				return
			}
		}
	}}

extension HomeTableViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		showScreen(at: indexPath)
	}

	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 0 {
			return 0
		}
		
		return 80
	}

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let view = UIView()
		view.backgroundColor = .clear
		
		return view
	}
}

extension HomeTableViewController: UITableViewDataSource {
	
    func numberOfSections(in tableView: UITableView) -> Int {
		return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let section = sections[section]

		return section.cellConfigurators.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cellConfigurator = sections[indexPath.section].cellConfigurators[indexPath.item]
		let cell = tableView.dequeueReusableCell(withIdentifier: cellConfigurator.viewAnyType.stringName(), for: indexPath)

		cellConfigurator.configureAny(cell: cell)

        return cell
    }
}

// MARK: - Update test state.

extension HomeTableViewController {
	func showTestResultScreen() {
		showExposureSubmission(with: homeInteractor.testResult)
	}

	func showAlreadyDidTestScreen() {
		delegate?.showAlreadyDidTestScreen()
	}
	
	func updateTestResultState() {
		homeInteractor.reloadActionSection()
		homeInteractor.updateTestResults()
	}
}

extension HomeTableViewController: ExposureStateUpdating {
	func updateExposureState(_ state: ExposureManagerState) {
		homeInteractor.state.exposureManagerState = state
		reloadData()
	}
}

extension HomeTableViewController: ENStateHandlerUpdating {
	func updateEnState(_ state: ENStateHandler.State) {
		homeInteractor.state.enState = state
		reloadData()
	}
}

extension HomeTableViewController: NavigationBarOpacityDelegate {
	var preferredNavigationBarOpacity: CGFloat {
		let alpha = (tableView.adjustedContentInset.top + tableView.contentOffset.y) / tableView.contentInset.top
		return max(0, min(alpha, 1))
	}
}
