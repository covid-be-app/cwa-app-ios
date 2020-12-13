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
class BEOnlineDynamicTextTests: XCTestCase {
	private func dynamicTextsURL(_ environment: BEEnvironment) -> URL {
		let dynamicTextsURL = URL(string: "https://coronalert-\(environment.urlSuffix()).ixor.be")!
		return dynamicTextsURL.appendingPathComponent("dynamictext/dynamicTextsV2.json")
	}
	
	func testURL() throws {
		let configuration = HTTPClient.Configuration.backendBaseURLs
		let urlToTest = dynamicTextsURL(.test)
		
		XCTAssertEqual(configuration.dynamicTextsURL,urlToTest)
    }
	
	func testEnvironments() throws {
		try BEEnvironment.allCases.forEach{ environment in
			try testDynamicTextOnUrl(dynamicTextsURL(environment))
		}
	}
	
	func testDynamicTextOnUrl(_ url: URL) throws {
		let data = try Data(contentsOf: url)
		let decoder = JSONDecoder()
		let result = try decoder.decode(BEDynamicText.self, from: data)
		
		try BEDynamicTextService.validateLoadedText(result)
	}

}
