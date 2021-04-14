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
import ExposureNotification

extension AppDelegate: ExposureSummaryProvider {
	func detectExposure(completion: @escaping (ENExposureDetectionSummary?) -> Void) {

		self.client.exposureConfiguration { configuration in
			if let configuration = configuration {
				self.exposureDetection = ExposureDetection(
					configuration: configuration,
					delegate: self.exposureDetectionExecutor
				)
				
				self.exposureDetection?.start { result in
					switch result {
					case .success(let summary):
						completion(summary)
					case .failure(let error):
						self.showError(exposure: error)
						completion(nil)
					}
				}
			} else {
				Log.debug("Failed to download configuration")
				completion(nil)
			}
		}
	}
	
	func getWindows(summary: ENExposureDetectionSummary, completion: @escaping WindowsCompletion) {
		_ = self.exposureManager.getExposureWindows(summary: summary) { windows, error in
			if let windows = windows {
				completion(windows)
			} else {
				Log.error("Failed to get windows", error: error)
				completion(nil)
			}
		}
	}

	private func showError(exposure didEndPrematurely: ExposureDetection.DidEndPrematurelyReason) {

		guard
			let rootController = window?.rootViewController,
			let alert = didEndPrematurely.errorAlertController(rootController: rootController)
		else {
			return
		}

		func _showError() {
			rootController.present(alert, animated: true, completion: nil)
		}

		if rootController.presentedViewController != nil {
			rootController.dismiss(
				animated: true,
				completion: _showError
			)
		} else {
			rootController.present(alert, animated: true, completion: nil)
		}
	}
}
