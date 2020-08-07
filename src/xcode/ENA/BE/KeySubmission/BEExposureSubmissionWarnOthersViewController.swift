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
	
	lazy var beExposureSubmissionService: BEExposureSubmissionService = {
		guard let beService = exposureSubmissionService as? BEExposureSubmissionService else {
			fatalError("Wrong exposure submission service subclass")
		}
		
		return beService
	}()

	lazy var beCoordinator: BEExposureSubmissionCoordinator  = {
		guard let beCoordinator = coordinator as? BEExposureSubmissionCoordinator else {
			fatalError("Wrong coordinator subclass")
		}
		
		return beCoordinator
	}()

	override init?(coder: NSCoder, coordinator: ExposureSubmissionCoordinating, exposureSubmissionService: ExposureSubmissionService) {
		super.init(coder: coder, coordinator: coordinator, exposureSubmissionService: exposureSubmissionService)
	}
	
	override func startSubmitProcess() {
		beExposureSubmissionService.retrieveDiagnosisKeys { result in
			switch result {
			case .failure(let error):
				switch error {
				case .noKeys:
					self.coordinator!.showThankYouScreen()
					// Custom error handling for EN framework related errors.
				case .internal, .unsupported, .rateLimited:
					self.showENErrorAlert(error)
				default:
					logError(message: "error: \(error.localizedDescription)", level: .error)
					let alert = self.setupErrorAlert(message: error.localizedDescription)
					self.present(alert, animated: true)
				}
				
			case .success(let keys):
				self.beCoordinator.showSelectCountries(keys)
			}
		}
	}
}
