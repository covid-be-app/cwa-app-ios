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
import ExposureNotification

extension ENIntervalNumber {
	var dateInt:BEDateInt {
		get {
			let timeInterval = TimeInterval(self) * 600
			return String.fromDateWithoutTime(date: Date(timeIntervalSince1970: timeInterval)).dateInt
		}
	}
	
	// only use this for visualisation, never to do logic or comparisons
	// as we can have time zone issues
	var date:Date {
		get {
			return Date(timeIntervalSince1970: TimeInterval(self) * 600)
		}
	}
	
	static func fromDateInt(_ dateInt:BEDateInt) -> ENIntervalNumber {
		let string = String("\(dateInt)")
		let year = Int(string[0...4])
		let month = Int(string[4...6])
		let day = Int(string[6...8])
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(secondsFromGMT: 0)!

		let date = calendar.date(from: DateComponents(year:year,month:month,day:day))!
		
		return ENIntervalNumber(Int(date.timeIntervalSince1970) / 600)
	}
}
