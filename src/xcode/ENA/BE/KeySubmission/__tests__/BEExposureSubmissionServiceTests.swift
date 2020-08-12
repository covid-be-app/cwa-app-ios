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
import ExposureNotification
@testable import ENA

class BEExposureSubmissionServiceTests: XCTestCase {
	var keys:[ENTemporaryExposureKey] = []
	var dateFormatter:DateFormatter!
	
    override func setUpWithError() throws {
		// generate fake keys for the last 2 weeks
		let dayCount = 14
		let startDate = Calendar.current.date(byAdding: .day, value: -dayCount, to: Date(), wrappingComponents: true)!
		
		for x in 0..<dayCount+1 {
			let date = Calendar.current.date(byAdding: .day, value: x, to: startDate, wrappingComponents: true)!
			let key = ENTemporaryExposureKey()
			key.transmissionRiskLevel = .zero
			key.rollingPeriod = 100
			key.rollingStartNumber = ENIntervalNumber.fromDate(date)
			
			keys.append(key)
		}

		dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "YYYY-MM-dd"
	}

	// We want to test that the correct range of keys is returned.
	// if we don't apply any filtering all keys will be returned, but we are only interested in the keys in the range [t0 .. t3]
	// whereby t0 is the date the user is infectious
	// and t3 is the date on which the test result was communicated to the user
    func testGetKeys() throws {
		let keyRetrieval = MockDiagnosisKeysRetrieval(diagnosisKeysResult: (keys, nil))
		let client = ClientMock()
		let store = MockTestStore()
		let service = BEExposureSubmissionService(diagnosiskeyRetrieval: keyRetrieval, client: client, store: store)

		// receive result today
		let dateTestCommunicated = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
		
		// infectious 8 days ago
		let datePatientInfectious = Calendar.current.date(byAdding: .day, value: -8, to: dateTestCommunicated, wrappingComponents: true)!
		
		// did test 4 days ago
		let dateTestCollected = Calendar.current.date(byAdding: .day, value: -4, to: dateTestCommunicated, wrappingComponents: true)!
		
		let patientInfectiousDateString = dateFormatter.string(from:datePatientInfectious)
		let testCollectedDateString = dateFormatter.string(from:dateTestCollected)
		let testCommunicatedDateString = dateFormatter.string(from:dateTestCommunicated)
		
		store.mobileTestId = BEMobileTestId(datePatientInfectious: patientInfectiousDateString)
		store.testResult = TestResult(result: .positive, channel: .lab, dateCollected: testCollectedDateString, dateTestCommunicated: testCommunicatedDateString)

		service.retrieveDiagnosisKeys{ result in
			switch result {
			case .failure:
				XCTAssert(false)
			case .success(let keys):
				keys.forEach{ key in
					XCTAssert(datePatientInfectious <= key.rollingStartNumber.date,"Key \(key.rollingStartNumber.date) earlier than infectious date \(datePatientInfectious)")
					XCTAssert(dateTestCommunicated >= key.rollingStartNumber.date,"Key later than test communicated date")
				}
			}
		}
    }
}
