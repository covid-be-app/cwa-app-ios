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

struct TestResult : Codable, Hashable {
	
	static let positive = TestResult(result:.positive, channel:.lab, dateCollected: "2020-01-01", dateTestCommunicated: "2020-01-01")
	static let negative = TestResult(result:.negative, channel:.lab, dateCollected: "2020-01-01", dateTestCommunicated: "2020-01-01")
	static let invalid = TestResult(result:.invalid, channel:.lab, dateCollected: "2020-01-01", dateTestCommunicated: "2020-01-01")
	static let pending = TestResult(result:.pending, channel:.lab, dateCollected: "2020-01-01", dateTestCommunicated: "2020-01-01")

	static func positiveWithDate(_ date: Date = Date()) -> TestResult {
		let dateString = BEDateString.fromDateWithoutTime(date: date)
		
		return TestResult(result:.positive, channel:.lab, dateCollected: dateString, dateTestCommunicated: dateString)
	}
	
	enum Result: Int, Codable {
		case pending = 0
		case negative = 1
		case positive = 2
		case invalid = 3
	}
	
	enum Channel: Int, Codable {
		case unknown = 0
		case lab = 1
		case doctor = 2
		case callcenter = 3
	}

	let result:Result
	let resultChannel:Channel
	let dateSampleCollected:BEDateString   // t1
	let dateTestCommunicated:BEDateString  // t3
	
	init(result:Result,channel:Channel,dateCollected:BEDateString,dateTestCommunicated:BEDateString) {
		self.result = result
		self.resultChannel = channel
		self.dateSampleCollected = dateCollected
		self.dateTestCommunicated = dateTestCommunicated
	}
}
