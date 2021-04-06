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

class BEENAToolboxTests: XCTestCase {
	var app: XCUIApplication!

	override func setUpWithError() throws {
		continueAfterFailure = false
		app = XCUIApplication()
		setupSnapshot(app)
		app.setDefaults()
		app.launchArguments.append(contentsOf: ["-isOnboarded", "YES"])
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	private func openToolbox() {
		app.launch()

		XCTAssert(app.buttons["AppStrings.Home.rightBarButtonDescription"].waitForExistence(timeout: 5.0))
		XCTAssert(app.cells["BEAppStrings.BEHome.toolbox"].waitForExistence(timeout: 5.0))
		app.cells["BEAppStrings.BEHome.toolbox"].tap()

		XCTAssert(app.cells["BEAppStrings.BEToolbox.vaccinationInformation"].waitForExistence(timeout: 5.0))
		XCTAssert(app.cells["BEAppStrings.BEToolbox.testReservation"].waitForExistence(timeout: 5.0))
		XCTAssert(app.cells["BEAppStrings.BEToolbox.quarantineCertificate"].waitForExistence(timeout: 5.0))
		XCTAssert(app.cells["BEAppStrings.BEToolbox.passengerLocatorForm"].waitForExistence(timeout: 5.0))
		XCTAssert(app.cells["BEAppStrings.BEToolbox.declarationOfHonour"].waitForExistence(timeout: 5.0))
	}

	func test_toolboxFlow() throws {
		openToolbox()
		snapshot("ScreenShot_\(#function)_001")
	}

	func test_toolboxFlow_vaccin() throws {
		openToolbox()
		app.cells["BEAppStrings.BEToolbox.vaccinationInformation"].tap()
		XCTAssert(app.images["BEAppStrings.BEToolbox.vaccinationInformation"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
	}

	func test_toolboxFlow_test() throws {
		openToolbox()
		app.cells["BEAppStrings.BEToolbox.testReservation"].tap()
		XCTAssert(app.images["BEAppStrings.BEToolbox.testReservation"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
	}

	func test_toolboxFlow_quarantine() throws {
		openToolbox()
		app.cells["BEAppStrings.BEToolbox.quarantineCertificate"].tap()
		XCTAssert(app.images["BEAppStrings.BEToolbox.quarantineCertificate"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
	}

	func test_toolboxFlow_plf() throws {
		openToolbox()
		app.cells["BEAppStrings.BEToolbox.passengerLocatorForm"].tap()
		XCTAssert(app.images["BEAppStrings.BEToolbox.passengerLocatorForm"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
	}

	func test_toolboxFlow_honor() throws {
		openToolbox()
		app.cells["BEAppStrings.BEToolbox.declarationOfHonour"].tap()
		XCTAssert(app.images["BEAppStrings.BEToolbox.declarationOfHonour"].waitForExistence(timeout: 5.0))
		snapshot("ScreenShot_\(#function)_001")
	}

	
}
