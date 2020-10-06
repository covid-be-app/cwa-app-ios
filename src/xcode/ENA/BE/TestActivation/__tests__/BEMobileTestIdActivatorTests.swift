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
@testable import ENA

class BEMobileTestIdActivatorTests: XCTestCase {

	private func buildActivator(_ url:URL) -> BEMobileTestIdActivator? {
		let exposureSubmissionService = BEMockExposureSubmissionService()
		let navController = UINavigationController.init()
		return BEMobileTestIdActivator(exposureSubmissionService, parentViewController: navController, url: url, delegate: nil)
	}
	
    func testWrongURL() throws {
		let url = URL(string:"https://google.com")!
		let activator = buildActivator(url)
		XCTAssertNil(activator)
    }

    func testWrongURL2() throws {
		let url = URL(string:"https://coronalert.be/en/cona-alert-form/?pcr=0000000000000000")!
		let activator = buildActivator(url)
		XCTAssertNil(activator)
    }

    func testWrongURL3() throws {
		let url = URL(string:"https://coronalert.be/en/corona-alert-form")!
		let activator = buildActivator(url)
		XCTAssertNil(activator)
    }

    func testWrongURL4() throws {
		let url = URL(string:"https://coronalert.be/en/corona-alert-form/?pcr=000abc00xx")!
		let activator = buildActivator(url)
		XCTAssertNil(activator)
    }
    
	func testWrongURL5() throws {
		let url = URL(string:"https://coronalert.be/en/corona-alert-form/?pcr=123456789012345")!
		let activator = buildActivator(url)
		XCTAssertNil(activator)
    }
	
    func testCorrectURL() throws {
		let url = URL(string:"https://coronalert.be/en/corona-alert-form/?pcr=1234567890123456")!
		let activator = buildActivator(url)
		XCTAssertNotNil(activator)
    }

    func testCorrectURL2() throws {
		let url = URL(string:"https://coronalert.be/fr/formulaire-coronalert/?pcr=1234567890123456")!
		let activator = buildActivator(url)
		XCTAssertNotNil(activator)
    }

    func testCorrectURL3() throws {
		let url = URL(string:"https://coronalert.be/nl/coronalert-formulier/?pcr=1234567890123456")!
		let activator = buildActivator(url)
		XCTAssertNotNil(activator)
    }

    func testCorrectURL4() throws {
		let url = URL(string:"https://coronalert.be/de/coronalert-formular/?pcr=1234567890123456")!
		let activator = buildActivator(url)
		XCTAssertNotNil(activator)
    }
}
