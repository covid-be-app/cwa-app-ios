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

import XCTest

class ENAUITests: XCTestCase {
	var app: XCUIApplication!

	override func setUp() {
		continueAfterFailure = false
		app = XCUIApplication()
		#if targetEnvironment(simulator)
			setupSnapshot(app)
		#endif
		app.setDefaults()
		app.launchArguments.append(contentsOf: ["-isOnboarded", "NO"])
	}


	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func navigateThroughOnboarding() throws {
		app.buttons["AppStrings.Onboarding.onboardingLetsGo"].tap()
		XCTAssertTrue(app.buttons["AppStrings.Onboarding.onboardingContinue"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.Onboarding.onboardingContinue"].tap()
		XCTAssertTrue(app.buttons["AppStrings.Onboarding.onboardingInfo_enableLoggingOfContactsPage_button"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.Onboarding.onboardingInfo_enableLoggingOfContactsPage_button"].tap()
		XCTAssertTrue(app.buttons["AppStrings.Onboarding.onboardingContinue"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.Onboarding.onboardingContinue"].tap()
		XCTAssertTrue(app.buttons["AppStrings.Onboarding.onboardingContinue"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.Onboarding.onboardingContinue"].tap()
	}

	func test_0000_Generate_Screenshots_For_AppStore() throws {
		#if targetEnvironment(simulator)
			let snapshotsActive = true
		#else
			let snapshotsActive = false
		#endif

		app.setPreferredContentSizeCategory(accessibililty: .normal, size: .M)
		app.launch()

		//// ScreenShot_0001: Onboarding screen 1
		XCTAssertTrue(app.buttons["AppStrings.Onboarding.onboardingLetsGo"].waitForExistence(timeout: 5.0))
		if snapshotsActive { snapshot("AppStore_0001") }

		/// ScreenShot_0002: Homescreen (low risk)
		try? navigateThroughOnboarding()
		XCTAssert(app.images["AppStrings.Home.leftBarButtonDescription"].waitForExistence(timeout: 5.0))
		if snapshotsActive { snapshot("AppStore_0002") }
		app.swipeUp()
		sleep(1)
		if snapshotsActive { snapshot("AppStore_0002b") }

		//// ScreenShot_0003: Risk view (low risk)
		XCTAssertTrue(app.buttons["RiskLevelCollectionViewCell.topContainer"].waitForExistence(timeout: 5.0))
		app.buttons["RiskLevelCollectionViewCell.topContainer"].tap()
		XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5.0))
		if snapshotsActive { snapshot("AppStore_0003") }
		app.swipeUp()
		sleep(1)
		if snapshotsActive { snapshot("AppStore_0003b") }

		//// ScreenShot_0004: Settings > Risk exposure
		app.navigationBars.buttons.element(boundBy: 0).tap()
		XCTAssert(app.images["AppStrings.Home.leftBarButtonDescription"].waitForExistence(timeout: 5.0))
		app.swipeUp()
		XCTAssertTrue(app.cells["AppStrings.Home.settingsCardTitle"].waitForExistence(timeout: 5.0))
		app.cells["AppStrings.Home.settingsCardTitle"].tap()
		XCTAssertTrue(app.cells["AppStrings.Settings.tracingLabel"].waitForExistence(timeout: 5.0))
		app.cells["AppStrings.Settings.tracingLabel"].tap()
		XCTAssertTrue(app.images["AppStrings.ExposureNotificationSetting.accLabelEnabled"].waitForExistence(timeout: 5.0))
		if snapshotsActive { snapshot("AppStore_0004") }

		
		
		//// ScreenShot_0005: Test Options
		// todo: need accessibility for Settings (navigation bar back button)
		XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5.0))

		//// EU interop screen
		app.cells["BEAppStrings.BEExposureNotification.euInteroperability.euInteroperabilityCell"].tap()
		XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5.0))
		if snapshotsActive { snapshot("AppStore_0005") }
		app.swipeUp()
		if snapshotsActive { snapshot("AppStore_0006") }
		app.navigationBars.buttons.element(boundBy: 0).tap()
		XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5.0))

		app.navigationBars.buttons.element(boundBy: 0).tap()
		XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5.0))
		app.navigationBars.buttons.element(boundBy: 0).tap()

		// todo: need accessibility for Notify and Help
		app.swipeDown()
		XCTAssertTrue(app.buttons["AppStrings.Home.submitCardButton"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.Home.submitCardButton"].tap()
		// todo: need accessibility for Next
		XCTAssertTrue(app.buttons["AppStrings.ExposureSubmission.continueText"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.ExposureSubmission.continueText"].tap()

		XCTAssertTrue(app.alerts.firstMatch.exists)
		app.alerts.buttons.firstMatch.tap()
		XCTAssertTrue(app.buttons["BEAppStrings.BESelectSymptomsDate.next"].waitForExistence(timeout: 5.0))
		if snapshotsActive { snapshot("AppStore_0007") }

		app.buttons["BEAppStrings.BESelectSymptomsDate.next"].tap()
		XCTAssertTrue(app.buttons["BEAppStrings.BEMobileTestId.save"].waitForExistence(timeout: 5.0))
		if snapshotsActive { snapshot("AppStore_0008") }
		
		//// ScreenShot_0007: Share screen
		// todo: need accessibility for Back (navigation bar back button)
		XCTAssertTrue(app.buttons["AppStrings.AccessibilityLabel.close"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.AccessibilityLabel.close"].tap()
		app.swipeUp()
		XCTAssertTrue(app.cells["AppStrings.Home.infoCardShareTitle"].waitForExistence(timeout: 5.0))
		app.cells["AppStrings.Home.infoCardShareTitle"].tap()
		if snapshotsActive { snapshot("AppStore_0009") }

		print("Snapshot.screenshotsDirectory")
		print(Snapshot.screenshotsDirectory?.path ?? "unknown output directory")

	}


}
