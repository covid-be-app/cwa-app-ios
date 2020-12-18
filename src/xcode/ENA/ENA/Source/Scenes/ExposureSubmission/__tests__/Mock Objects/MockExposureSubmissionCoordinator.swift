//
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
//

@testable import ENA

import ExposureNotification

class MockExposureSubmissionCoordinator: ExposureSubmissionCoordinating {

	// MARK: - Attributes.
	var submitExposureCallback: (() -> Void)?

	weak var delegate: ExposureSubmissionCoordinatorDelegate?

	// MARK: - ExposureSubmissionCoordinator methods.

	func start(with: TestResult? = nil) { }

	func dismiss() { }
	
	func resetApp() { }

	func showOverviewScreen() { }

	func showTestResultScreen(with result: TestResult) { }

	func showHotlineScreen() { }

	func showTanScreen() { }

	func showWarnOthersScreen() { }

	func showThankYouScreen() { }
	
	func submitExposureKeys(_ exposureKeys: [ENTemporaryExposureKey]) {
		submitExposureCallback?()
	}
}
