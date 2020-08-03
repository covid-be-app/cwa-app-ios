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

class BEMobileTestIdTests: XCTestCase {

    func testGenerateId() throws {
		let testId = BEMobileTestId(datePatientInfectious: "2020-07-10")
		
		XCTAssertEqual(testId.id.count, 15)
		XCTAssertEqual(testId.checksum.count,2)
		XCTAssertEqual(testId.fullString.count,20)
		
		XCTAssertNotEqual(Int(testId.id),nil)
		XCTAssertNotEqual(Int(testId.checksum),nil)
		
		XCTAssertEqual((Int(testId.id)! * 100 + Int(testId.checksum)!) % 97,0)
		
		let registrationToken = testId.registrationToken
		let components = registrationToken.split(separator:"|")
		
		XCTAssertEqual(components.count, 2)
		
		let firstPart = String(components[0])
		let secondPart = String(components[1])
		
		XCTAssertEqual(firstPart,testId.id)
		XCTAssertEqual(secondPart,testId.datePatientInfectious)
   }
}
