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

    static func random(length: Int) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" as String
        var randomString: String = ""
		var bytes = [UInt8](repeating: 0, count: length)
		let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
		guard result == errSecSuccess else {
			fatalError("Error creating random bytes.")
		}

        for x in 0..<length {
			let randomValue = Int(bytes[x]) % base.count
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


extension String {
	func findFirstURL() -> (url: URL, range: NSRange)? {
		if
			let match = getFirstMatch(.link),
			let url = match.url {
			return (url: url, range: match.range)
		}
		
		return nil
	}
	
	func findFirstPhoneNumber() -> (phoneNumber: String, range: NSRange)? {
		if
			let match = getFirstMatch(.phoneNumber),
			let phoneNumber = match.phoneNumber {
			return (phoneNumber: phoneNumber, range: match.range)
		}
		
		return nil
	}

	private func getFirstMatch(_ type: NSTextCheckingResult.CheckingType) -> NSTextCheckingResult? {
		let detector = try? NSDataDetector(types: type.rawValue)
		
		guard let detect = detector else {
		   return nil
		}

		let matches = detect.matches(in: self, options: .reportCompletion, range: NSMakeRange(0, count))

		if matches.isEmpty {
			return nil
		}
		
		return matches[0]
	}
}
