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

import Foundation
import XCTest
@testable import ENA

class ExposureSubmissionWarnOthersViewControllerTests: XCTestCase {

	var service: BEMockExposureSubmissionService!
	var coordinator: MockExposureSubmissionCoordinator!

	override func setUp() {
		super.setUp()
		service = BEMockExposureSubmissionService()
		coordinator = MockExposureSubmissionCoordinator()
	}

	private func createVC() -> ExposureSubmissionWarnOthersViewController {
		AppStoryboard.exposureSubmission.initiate(viewControllerType: ExposureSubmissionWarnOthersViewController.self) { coder -> UIViewController? in
			BEExposureSubmissionWarnOthersViewController(coder: coder, coordinator: self.coordinator, exposureSubmissionService: self.service)
		}
	}

	func testSuccessfulSubmit() {
		let vc = createVC()
		_ = vc.view

		let expectSubmitExposure = self.expectation(description: "Call submitExposure")
		coordinator.submitExposureCallback = { expectSubmitExposure.fulfill() }

		// Trigger submission process.
		vc.startSubmitProcess()
		waitForExpectations(timeout: .short)
	}

	func testShowENErrorAlertInternal() {
		let vc = createVC()
		_ = vc.view

		let alert = vc.createENAlert(.internal)
		XCTAssert(alert.actions.count == 1)
		XCTAssert(alert.message == AppStrings.Common.enError11Description)
	}

	func testShowENErrorAlertUnsupported() {
		let vc = createVC()
		_ = vc.view

		let alert = vc.createENAlert(.unsupported)
		XCTAssert(alert.actions.count == 1)
		XCTAssert(alert.message == AppStrings.Common.enError5Description)
	}

	func testShowENErrorAlertRateLimited() {
		let vc = createVC()
		_ = vc.view

		let alert = vc.createENAlert(.rateLimited)
		XCTAssert(alert.actions.count == 1)
		XCTAssert(alert.message == AppStrings.Common.enError13Description)
	}
}
