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
import CryptoKit

struct BEMobileTestId {
	
	static let fakeId = "000000000000000"
	static let fakeDatePatientInfectious = "2020-01-01"
	
	static var fakeRegistrationToken:String {
		get {
			return "\(fakeId)|\(fakeDatePatientInfectious)"
		}
	}
	
	static var random:BEMobileTestId {
		get {
			return BEMobileTestId(datePatientInfectious: String.fromDateWithoutTime(date: Date()))
		}
	}
	
	// R1. This is a string because it can start with 0. 15 digits
	let id:String
	
	// 2 digits to make (t0.compactDateNumber|R1|checksum) % 97 == 0
	// Also a string because of 0 prefix possible (and we don't need to do calculations on these numbers individually)
	let checksum:String

	// Components used to calculate mobile test id
	let randomString:String				// R0
	let secretKey:SymmetricKey			// K
	let datePatientInfectious:BEDateString    // t0
	
	let creationDate:Date

	var fullString:String {
		let stringToSplit = "\(id)\(checksum)"
		let part1 = stringToSplit[0...4]
		let part2 = stringToSplit[4...8]
		let part3 = stringToSplit[8...12]
		let part4 = stringToSplit[12...16]
		let part5 = stringToSplit[16...17]

		return "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
	}
	
	// the string used as registrationToken in the networking calls to fetch the test result
	var registrationToken:String {
		get {
			return "\(id)|\(datePatientInfectious)"
		}
	}
	
	var secretKeyBase64String:String {
		get {
			return secretKey.withUnsafeBytes { bytes in
				let data = Data.init(bytes: bytes.baseAddress!, count: bytes.count)
				
				return data.base64EncodedString()
			}
		}
	}

	// this is the t0 date, in YYYY-MM-DD format
	init(datePatientInfectious:BEDateString) {
		#if DEBUG
			if datePatientInfectious.dateWithoutTime == nil {
				preconditionFailure("Wrong format")
			}
		#endif
		
		self.datePatientInfectious = datePatientInfectious
		
		var R1:String?
		var localSecretKey:SymmetricKey!
		var localRandomString:String!
		var info:String!
		
		while(R1 == nil) {
			localSecretKey = Self.generateK()
			localRandomString = Self.generateR0()
			info = Self.generateInfo(R0: localRandomString, t0: datePatientInfectious)
			R1 = Self.calculateR1(info:info,K:localSecretKey)
		}
		
		id = R1!
		randomString = localRandomString
		secretKey = localSecretKey
		
		let valueToCalculateChecksumOn = Decimal(string:"\(datePatientInfectious.compactDateInt)\(id)")!
		checksum = String.init(format:"%02d",Self.calculateCheckDigits(R1:valueToCalculateChecksumOn))
		
		creationDate = Date()
	}
}

extension BEMobileTestId {
	private static func generateK() -> SymmetricKey {
		return SymmetricKey(size:.bits128)
	}
	
	private static func generateR0() -> String {
		return String.random(length:16)
	}
	
	private static func generateInfo(R0:String,t0:String) -> String {
		return R0 + t0 + "TEST REQUEST"
	}

	private static func calculateR1(info:String,K:SymmetricKey) -> String? {
		let authentication = HMAC<SHA256>.authenticationCode(for: info.data(using: .utf8)!, using: K)

		var byteBuffer: [UInt8] = []

		authentication.withUnsafeBytes{ bytes in
			byteBuffer = bytes.suffix(7)
		}

		let firstNumber = UInt64(byteBuffer[0]) + (UInt64(byteBuffer[1]) << 8) + ((UInt64(byteBuffer[2]) & 0xF) << 16)
		let secondNumber = (UInt64(byteBuffer[2]) >> 4) + (UInt64(byteBuffer[3]) << 4) + (UInt64(byteBuffer[4]) << 12)
		let thirdNumber = UInt64(byteBuffer[5]) + ((UInt64(byteBuffer[6]) & 0x3) << 8)

		let n1mod = firstNumber % 1000000
		let n2mod = secondNumber % 1000000
		let n3mod = thirdNumber % 1000

		let R1 = String.init(format:"%06d%06d%03d",n1mod,n2mod,n3mod)
		assert(R1.count == 15)

		if Int(R1) == 0 {
			return nil
		}
		
		return R1
	}
	
	private static func calculateCheckDigits(R1:Decimal) -> Int {
		let mod = NSDecimalNumber(decimal:(97 - (R1 * 100) % 97))
		
		return Int(truncating: mod)
	}
}

extension BEMobileTestId : Codable {

}

extension BEMobileTestId {
	static func calculateDatePatientInfectious(symptomsStartDate:Date? = nil) -> Date {
		
		if let startDate = symptomsStartDate {
			return Calendar.current.date(byAdding: .day, value: -2, to: startDate)!
		}

		return Calendar.current.date(byAdding: .day, value: -2, to: Date())!
	}
}
