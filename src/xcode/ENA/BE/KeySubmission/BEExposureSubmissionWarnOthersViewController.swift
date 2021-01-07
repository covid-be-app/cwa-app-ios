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

class BEExposureSubmissionWarnOthersViewController: ExposureSubmissionWarnOthersViewController {
	
	override init(coordinator: ExposureSubmissionCoordinating, exposureSubmissionService: BEExposureSubmissionService) {
		super.init(coordinator: coordinator, exposureSubmissionService: exposureSubmissionService)
	}
	
	override func startSubmitProcess() {
		exposureSubmissionService?.retrieveDiagnosisKeys { result in
			switch result {
			case .failure(let error):
				switch error {
				case .noKeys:
					self.exposureSubmissionService?.finalizeSubmissionWithoutKeys()
					self.coordinator!.showThankYouScreen()
					// Custom error handling for EN framework related errors.
				case .internal, .unsupported, .rateLimited:
					self.showENErrorAlert(error)
				default:
					logError(message: "error: \(error.localizedDescription)", level: .error)
					let alert = Self.setupErrorAlert(message: error.localizedDescription)
					self.present(alert, animated: true)
				}
				
			case .success(let keys):
				self.coordinator!.submitExposureKeys(keys)
			}
		}
	}
}
