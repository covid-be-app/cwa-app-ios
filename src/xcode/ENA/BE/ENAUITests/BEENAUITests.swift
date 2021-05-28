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
	}

	func testGetKeyWithoutSymptoms() throws {
		app.launch()

		// only run if home screen is present
		XCTAssert(app.images["AppStrings.Home.leftBarButtonDescription"].waitForExistence(timeout: 5.0))

		app.swipeUp()
		
		XCTAssertTrue(app.buttons["AppStrings.Home.submitCardButton"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.Home.submitCardButton"].tap()
		// todo: need accessibility for Next
		XCTAssertTrue(app.buttons["AppStrings.ExposureSubmission.continueText"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
		app.buttons["AppStrings.ExposureSubmission.continueText"].tap()
		XCTAssertTrue(app.alerts.firstMatch.exists)
		snapshot("ScreenShot_\(#function)_002")

		// tap NO
		app.alerts.buttons.element(boundBy: 1).tap()

		XCTAssertTrue(app.buttons["BEAppStrings.BEMobileTestId.save"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_003")

		app.buttons["BEAppStrings.BEMobileTestId.save"].tap()

		XCTAssert(app.images["AppStrings.Home.leftBarButtonDescription"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_004")
	}
	
	func testGetKeyWithSymptoms() throws {
		app.launch()

		// only run if home screen is present
		XCTAssert(app.images["AppStrings.Home.leftBarButtonDescription"].waitForExistence(timeout: 5.0))
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
		snapshot("ScreenShot_\(#function)_001")
		app.buttons["BEAppStrings.BESelectSymptomsDate.next"].tap()
		XCTAssertTrue(app.buttons["BEAppStrings.BEMobileTestId.save"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_002")

		app.buttons["BEAppStrings.BEMobileTestId.save"].tap()

		XCTAssert(app.images["AppStrings.Home.leftBarButtonDescription"].waitForExistence(timeout: 5.0))
		app.swipeUp()
	}
	
	func testPositiveSendKeys() throws {
		app.launchArguments.append(contentsOf: ["-testResult", "POSITIVE"])
		app.launchArguments.append(contentsOf:[UITestingParameters.ExposureSubmission.useMock.rawValue])
		app.launch()

		XCTAssertTrue(app.buttons["AppStrings.Home.resultCardShowResultButton"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
		app.swipeUp()
		app.buttons["AppStrings.Home.resultCardShowResultButton"].tap()

		XCTAssertTrue(app.buttons["BEAppStrings.BETestResult.next"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_002")
		app.buttons["BEAppStrings.BETestResult.next"].tap()

		XCTAssertTrue(app.alerts["BEAppStrings.BEWarnOthers.alert"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_003")

		app.alerts["BEAppStrings.BEWarnOthers.alert"].buttons.element(boundBy: 0).tap()
		XCTAssertTrue(app.buttons["BEAppStrings.BEExposureSubmissionSuccess.button"].waitForExistence(timeout: 5.0))

		snapshot("ScreenShot_\(#function)_008")
		app.swipeUp()
		sleep(1)
		snapshot("ScreenShot_\(#function)_009")
		app.buttons["BEAppStrings.BEExposureSubmissionSuccess.button"].tap()
		sleep(1)
		snapshot("ScreenShot_\(#function)_010")
	}
	
	func testIncreasedRisk() throws {
		app.launchArguments.append(contentsOf: ["-riskLevel", "HIGH"])
		app.launch()

		XCTAssert(app.images["AppStrings.Home.leftBarButtonDescription"].waitForExistence(timeout: 5.0))
		XCTAssertTrue(app.buttons["RiskLevelCollectionViewCell.topContainer"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
		app.buttons["RiskLevelCollectionViewCell.topContainer"].tap()
		XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_002")
		app.swipeUp()
		snapshot("ScreenShot_\(#function)_003")
	}

	func testUnknownRisk() throws {
		app.launchArguments.append(contentsOf: ["-riskLevel", "UNKNOWN"])
		app.launch()

		XCTAssert(app.images["AppStrings.Home.leftBarButtonDescription"].waitForExistence(timeout: 5.0))
		XCTAssertTrue(app.buttons["RiskLevelCollectionViewCell.topContainer"].waitForExistence(timeout: 5.0))
		app.buttons["RiskLevelCollectionViewCell.topContainer"].tap()
		XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
		app.swipeUp()
		snapshot("ScreenShot_\(#function)_002")
	}

	func testExposureStopped() throws {
		app.launchArguments.append(contentsOf: ["-riskLevel", "INACTIVE"])
		app.launch()

		XCTAssert(app.images["AppStrings.Home.leftBarButtonDescription"].waitForExistence(timeout: 5.0))
		XCTAssertTrue(app.buttons["RiskLevelCollectionViewCell.topContainer"].waitForExistence(timeout: 5.0))
		app.buttons["RiskLevelCollectionViewCell.topContainer"].tap()
		XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
		app.swipeUp()
		snapshot("ScreenShot_\(#function)_002")
	}

	func testWebFormWithoutSymptoms() throws {
		app.launchArguments.append(contentsOf: ["-openWebForm", "https://coronalert.be/en/corona-alert-form/?pcr=0000000000000000"])
		app.launch()

		// tap NO
		app.alerts.buttons.element(boundBy: 1).tap()
		XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5.0))
	}

	func testWebFormWithSymptoms() throws {
		app.launchArguments.append(contentsOf: ["-openWebForm", "https://coronalert.be/en/corona-alert-form/?pcr=0000000000000000"])
		app.launch()

		// tap YES
		app.alerts.buttons.firstMatch.tap()

		XCTAssertTrue(app.buttons["BEAppStrings.BESelectSymptomsDate.next"].waitForExistence(timeout: 5.0))
		app.buttons["BEAppStrings.BESelectSymptomsDate.next"].tap()

		XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5.0))
	}
	
	func testNegativeTestResult() throws {
		app.launchArguments.append(contentsOf: ["-testResult", "NEGATIVE"])
		app.launch()
		app.swipeUp()

		XCTAssertTrue(app.buttons["AppStrings.Home.resultCardShowResultButton"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
		app.swipeUp()
		snapshot("ScreenShot_\(#function)_002")
		app.swipeDown()
		app.buttons["AppStrings.Home.resultCardShowResultButton"].tap()
		sleep(1)
		snapshot("ScreenShot_\(#function)_003")
	}
	
	func testPendingTestResult() throws {
		app.launchArguments.append(contentsOf: ["-testResult", "PENDING"])
		app.launch()
		app.swipeUp()

		XCTAssertTrue(app.buttons["AppStrings.Home.resultCardShowResultButton"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
		app.swipeUp()
		snapshot("ScreenShot_\(#function)_002")
		
		if !app.buttons["AppStrings.Home.resultCardShowResultButton"].visible() {
			app.swipeDown()
		}
		
		app.buttons["AppStrings.Home.resultCardShowResultButton"].tap()
		sleep(1)
		snapshot("ScreenShot_\(#function)_003")
	}

	func testPositiveTestResult() throws {
		app.launchArguments.append(contentsOf: ["-testResult", "POSITIVE"])
		app.launchArguments.append(contentsOf:[UITestingParameters.ExposureSubmission.useMock.rawValue])
		app.launch()

		XCTAssertTrue(app.buttons["AppStrings.Home.resultCardShowResultButton"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
		app.swipeUp()
		snapshot("ScreenShot_\(#function)_002")
		app.buttons["AppStrings.Home.resultCardShowResultButton"].tap()
		sleep(1)
		snapshot("ScreenShot_\(#function)_003")

		XCTAssertTrue(app.buttons["BEAppStrings.BETestResult.next"].waitForExistence(timeout: 5.0))
	}
	
	func testSendKeys() throws {
		app.launchArguments.append(contentsOf: ["-testResult", "POSITIVE"])
		app.launchArguments.append(contentsOf:[UITestingParameters.ExposureSubmission.useMock.rawValue])
		app.launch()

		app.swipeUp(velocity: .slow)
		XCTAssertTrue(app.buttons["AppStrings.Home.resultCardShowResultButton"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.Home.resultCardShowResultButton"].tap()

		// make sure the close button is gone
		XCTAssertFalse(app.buttons["AppStrings.AccessibilityLabel.close"].waitForExistence(timeout: 5.0))
		XCTAssertTrue(app.buttons["BEAppStrings.BETestResult.next"].waitForExistence(timeout: 5.0))
		app.buttons["BEAppStrings.BETestResult.next"].tap()

		XCTAssertTrue(app.alerts["BEAppStrings.BEWarnOthers.alert"].waitForExistence(timeout: 5.0))
		app.alerts["BEAppStrings.BEWarnOthers.alert"].buttons.element(boundBy: 0).tap()
		XCTAssertTrue(app.buttons["BEAppStrings.BEExposureSubmissionSuccess.button"].waitForExistence(timeout: 5.0))
		app.swipeUp()
	}

	func testCancelSendKeys() throws {
		app.launchArguments.append(contentsOf: ["-testResult", "POSITIVE"])
		app.launchArguments.append(contentsOf:[UITestingParameters.ExposureSubmission.useMock.rawValue])
		app.launch()

		app.swipeUp(velocity: .slow)
		XCTAssertTrue(app.buttons["AppStrings.Home.resultCardShowResultButton"].waitForExistence(timeout: 5.0))
		app.buttons["AppStrings.Home.resultCardShowResultButton"].tap()

		// make sure the close button is gone
		XCTAssertFalse(app.buttons["AppStrings.AccessibilityLabel.close"].waitForExistence(timeout: 5.0))
		XCTAssertTrue(app.buttons["BEAppStrings.BETestResult.next"].waitForExistence(timeout: 5.0))
		app.buttons["BEAppStrings.BETestResult.next"].tap()

		XCTAssertTrue(app.alerts["BEAppStrings.BEWarnOthers.alert"].waitForExistence(timeout: 5.0))
		app.alerts["BEAppStrings.BEWarnOthers.alert"].buttons.element(boundBy: 1).tap()
		XCTAssertFalse(app.buttons["BEAppStrings.BEExposureSubmissionSuccess.button"].waitForExistence(timeout: 5.0))
		XCTAssertTrue(app.buttons["AppStrings.Home.resultCardShowResultButton"].waitForExistence(timeout: 5.0))
	}
	
	func testMobileDataSettings() {
		app.launch()

		XCTAssert(app.images["AppStrings.Home.leftBarButtonDescription"].waitForExistence(timeout: 5.0))
		app.swipeUp()
		XCTAssertTrue(app.cells["AppStrings.Home.settingsCardTitle"].waitForExistence(timeout: 5.0))
		app.cells["AppStrings.Home.settingsCardTitle"].tap()
		XCTAssertTrue(app.cells["BEAppStrings.BESettings.mobileDataLabel"].waitForExistence(timeout: 5.0))
		app.cells["BEAppStrings.BESettings.mobileDataLabel"].tap()
		XCTAssertTrue(app.images["BEAppStrings.BESettings.BEMobileDataUsageSettings.image"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
	}
	
	func testSendCoviCodes() {
		app.launchArguments.append(contentsOf:[UITestingParameters.ExposureSubmission.useMock.rawValue])
		app.launch()
		XCTAssertTrue(app.cells["BEAppStrings.BEHome.coviCode"].waitForExistence(timeout: 5.0))
		app.cells["BEAppStrings.BEHome.coviCode"].tap()
		snapshot("ScreenShot_\(#function)_001")
		XCTAssertTrue(app.buttons["BEAppStrings.BECoviCode.submit"].waitForExistence(timeout: 5.0))
		app.buttons["BEAppStrings.BECoviCode.submit"].tap()
		XCTAssertTrue(app.alerts.firstMatch.exists)
		snapshot("ScreenShot_\(#function)_002")

		// tap NO
		app.alerts.buttons.element(boundBy: 1).tap()

		app.textFields.element(boundBy: 0).tap()
		app.textFields.element(boundBy: 0).typeText("111111111111")
		snapshot("ScreenShot_\(#function)_003")

		app.alerts.buttons.element(boundBy: 1).tap()
		XCTAssertTrue(app.buttons["BEAppStrings.BEExposureSubmissionSuccess.button"].waitForExistence(timeout: 5.0))

	}
}
