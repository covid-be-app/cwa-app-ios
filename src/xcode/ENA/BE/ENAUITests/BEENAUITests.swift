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

import XCTest

class BEENAUITests: XCTestCase {
	var app: XCUIApplication!

	override func setUpWithError() throws {
		continueAfterFailure = false
		app = XCUIApplication()
		setupSnapshot(app)
		app.setDefaults()
		app.launchArguments.append(contentsOf: ["-isOnboarded", "YES"])
		app.launchArguments += ["-AppleLanguages", "(nl)"]
		app.launchArguments += ["-AppleLocale", "nl_BE"]

	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testGetKeyWithoutSymptoms() throws {
		app.launch()

		// only run if home screen is present
		XCTAssert(app.buttons["AppStrings.Home.rightBarButtonDescription"].waitForExistence(timeout: 5.0))

		app.swipeUp()
		
		XCTAssertTrue(app.buttons["AppStrings.Home.submitCardButton"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.Home.submitCardButton"].tap()
		// todo: need accessibility for Next
		XCTAssertTrue(app.buttons["AppStrings.ExposureSubmission.continueText"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.ExposureSubmission.continueText"].tap()
		XCTAssertTrue(app.alerts.firstMatch.exists)
		
		// tap NO
		app.alerts.buttons.element(boundBy: 1).tap()

		XCTAssertTrue(app.buttons["BEAppStrings.BEMobileTestId.save"].waitForExistence(timeout: 5.0))
		
		app.buttons["BEAppStrings.BEMobileTestId.save"].tap()

		XCTAssert(app.buttons["AppStrings.Home.rightBarButtonDescription"].waitForExistence(timeout: 5.0))
	}
	
	func testGetKeyWithSymptoms() throws {
		app.launch()

		// only run if home screen is present
		XCTAssert(app.buttons["AppStrings.Home.rightBarButtonDescription"].waitForExistence(timeout: 5.0))

		app.swipeUp()
		
		XCTAssertTrue(app.buttons["AppStrings.Home.submitCardButton"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.Home.submitCardButton"].tap()
		// todo: need accessibility for Next
		XCTAssertTrue(app.buttons["AppStrings.ExposureSubmission.continueText"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.ExposureSubmission.continueText"].tap()
		XCTAssertTrue(app.alerts.firstMatch.exists)
		
		// tap YES
		app.alerts.buttons.firstMatch.tap()

		XCTAssertTrue(app.buttons["BEAppStrings.BESelectSymptomsDate.next"].waitForExistence(timeout: 5.0))

		app.buttons["BEAppStrings.BESelectSymptomsDate.next"].tap()

		XCTAssertTrue(app.buttons["BEAppStrings.BEMobileTestId.save"].waitForExistence(timeout: 5.0))
		
		app.buttons["BEAppStrings.BEMobileTestId.save"].tap()

		XCTAssert(app.buttons["AppStrings.Home.rightBarButtonDescription"].waitForExistence(timeout: 5.0))
	}
}
