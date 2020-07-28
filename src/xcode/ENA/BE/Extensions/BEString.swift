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

extension String {
	static func fromDateWithoutTime(date:Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY-MM-dd"
		
		return formatter.string(from: date)
	}
	
	func dateWithoutTime() -> Date? {
		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY-MM-dd"
		
		return formatter.date(from: self)
	}
}

extension String {

    static func random(length: Int) -> String {

        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" as String
        var randomString: String = ""

        for _ in 0..<length {

            let randomValue = arc4random_uniform(UInt32(base.count))
            let index = String.Index(utf16Offset: Int(randomValue), in: base)
            randomString += "\(base[index])"
        }

        return randomString
    }
}

extension String {
	subscript(_ i: Int) -> String {
	  let idx1 = index(startIndex, offsetBy: i)
	  let idx2 = index(idx1, offsetBy: 1)
	  return String(self[idx1..<idx2])
	}

	subscript (r: Range<Int>) -> String {
	  let start = index(startIndex, offsetBy: r.lowerBound)
	  let end = index(startIndex, offsetBy: r.upperBound)
	  return String(self[start ..< end])
	}

	subscript (r: CountableClosedRange<Int>) -> String {
	  let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
	  let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
	  return String(self[startIndex..<endIndex])
	}
}
