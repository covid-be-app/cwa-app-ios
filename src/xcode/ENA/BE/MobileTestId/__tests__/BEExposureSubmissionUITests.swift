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
import XCTest

class BEExposureSubmissionUITests: XCTestCase {

	// MARK: - Attributes.
	
	var app: XCUIApplication!

	// MARK: - Setup.

	override func setUpWithError() throws {
		continueAfterFailure = false
		app = XCUIApplication()
		setupSnapshot(app)
		app.setDefaults()
		app.launchArguments.append(contentsOf: ["-isOnboarded", "YES"])
	}

	// MARK: - Test cases.

	func test_MobileTestIdOpened() throws {
		launch()

		// Open Intro screen.
		XCTAssert(app.collectionViews.buttons["AppStrings.Home.submitCardButton"].waitForExistence(timeout: .long))
		app.collectionViews.buttons["AppStrings.Home.submitCardButton"].tap()
		XCTAssert(app.navigationBars["ExposureSubmissionNavigationController"].waitForExistence(timeout: .medium))

		// Click next button.
		XCTAssertNotNil(app.buttons["AppStrings.ExposureSubmission.continueText"].waitForExistence(timeout: .medium))
		app.buttons["AppStrings.ExposureSubmission.continueText"].tap()

		// Accept the alert.
		XCTAssertTrue(app.alerts.firstMatch.exists)
		app.alerts.buttons.firstMatch.tap()
		XCTAssertNotNil(app.buttons["BEAppStrings.BEMobileTestId.select"].waitForExistence(timeout: .medium))
	}
}

// MARK: - Helpers.

extension BEExposureSubmissionUITests {

	private func type(_ app: XCUIApplication, text: String) {
		text.forEach {
			app.keys[String($0)].tap()
		}
	}

	/// Launch and wait until the app is ready.
	private func launch() {
		app.launch()
		XCTAssert(app.buttons["AppStrings.Home.rightBarButtonDescription"].waitForExistence(timeout: .long))
	}
}

private extension TimeInterval {
	static let short = 1.0
	static let medium = 3.0
	static let long = 5.0
}
