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

import Foundation
import NotificationCenter

extension AppDelegate: ENATaskExecutionDelegate {

	/// This method executes the background tasks needed for: a) fetching test results and b) performing exposure detection requests
	// :BE: Add fake requests and refactor
	func executeENABackgroundTask(completion: @escaping ((Bool) -> Void)) {
		self.fakeRequestsExecutor.execute {
			log(message: "Fake requests done")
			self.executeFetchTestResults {
				log(message: "Fetch test results done")
				self.executeExposureDetectionRequest {
					log(message: "Exposure detection done")
					self.updateDynamicTexts {
						log(message: "Dynamic text updates done")
						completion(true)
					}
				}
			}
		}
	}

	/// This method executes a  test result fetch, and if it is successful, and the test result is different from the one that was previously
	/// part of the app, a local notification is shown.
	private func executeFetchTestResults(completion: @escaping (() -> Void)) {
		log(message: "Start fetch test results...")
		// :BE: replace ENAExposureSubmissionService with BEExposureSubmissionService
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: exposureManager, client: client, store: store)
		exposureSubmissionService = service

		// after showing the test result to the user, remove it after a certain time
		service.deleteTestResultIfOutdated()
		
		if store.registrationToken != nil && store.testResultReceivedTimeStamp == nil {
			// :BE: see if we passed the validity time for this test result
			if !service.deleteMobileTestIdIfOutdated() {
				self.exposureSubmissionService?.getTestResult { result in
					switch result {
					case .failure(let error):
						logError(message: error.localizedDescription)
					case .success(let testResult):
						
						// :BE: testresult enum to struct
						if testResult.result != .pending {
							UNUserNotificationCenter.current().presentNotification(
								title: AppStrings.LocalNotifications.testResultsTitle,
								body: AppStrings.LocalNotifications.testResultsBody,
								identifier: ENATaskIdentifier.exposureNotification.backgroundTaskSchedulerIdentifier + ".test-result"

							)
						}
					}
					completion()
				}
				return
			}
		}
		
		completion()
	}

	/// This method performs a check for the current exposure detection state. Only if the risk level has changed compared to the
	/// previous state, a local notification is shown.
	private func executeExposureDetectionRequest(completion: @escaping (() -> Void)) {
		log(message: "Start exposure detection...")

		// At this point we are already in background so it is safe to assume background mode is available.
		riskProvider.configuration.detectionMode = .fromBackgroundStatus(.available)

		riskProvider.requestRisk(userInitiated: false) { risk in
			// present a notification if the risk score has increased.
			if let risk = risk,
				risk.riskLevelHasChanged {
				UNUserNotificationCenter.current().presentNotification(
					title: AppStrings.LocalNotifications.detectExposureTitle,
					body: AppStrings.LocalNotifications.detectExposureBody,
					identifier: ENATaskIdentifier.exposureNotification.backgroundTaskSchedulerIdentifier + ".risk-detection"
				)
			}
			completion()
		}
	}
	
	private func updateDynamicTexts(completion: @escaping (() -> Void)) {
		log(message: "Start dynamic text updates...")
		let dynamicInformationTextService = BEDynamicInformationTextService()
		let dynamicInformationTextDownloadService = BEDynamicTextDownloadService(client: client, textService: dynamicInformationTextService, url: client.configuration.dynamicInformationTextsURL)
		
		dynamicInformationTextDownloadService.downloadTextsIfNeeded {
			let dynamicNewsTextService = BEDynamicNewsTextService()
			let dynamicNewsTextDownloadService = BEDynamicTextDownloadService(client: self.client, textService: dynamicNewsTextService, url: self.client.configuration.dynamicNewsTextsURL)

			dynamicNewsTextDownloadService.downloadTextsIfNeeded {
				completion()
			}
		}
	}
}
