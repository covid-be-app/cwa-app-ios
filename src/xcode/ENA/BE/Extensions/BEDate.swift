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

// Int = YYYYMMDD
typealias BEDateInt = Int

// String = "YYYY-MM-DD"
typealias BEDateString = String

extension BEDateString {
	static func fromDateWithoutTime(date:Date) -> BEDateString {
		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY-MM-dd"
		
		return formatter.string(from: date)
	}
	
	var dateWithoutTime:Date? {
		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY-MM-dd"
		
		return formatter.date(from: self)
	}
	
	// YYYYMMDD
	var dateInt:BEDateInt {
		get {
			let components = self.split(separator: "-")
			return Int("\(components[0])\(components[1])\(components[2])")!
		}
	}
	
	// this is used to convert YYYY-MM-DD strings into YYMMDD representation
	var compactDateInt:Int{
		#if DEBUG
			guard let _ = dateWithoutTime else {
				fatalError("Wrong string format")
			}
		#endif
		
		let components = self.split(separator: "-")
		let year = String(components[0])[2...4]
		
		return Int("\(year)\(components[1])\(components[2])")!
	}
}

extension BEDateInt {
	static func fromDate(_ date:Date) -> BEDateInt {
		return BEDateString.fromDateWithoutTime(date: date).dateInt
	}
}
