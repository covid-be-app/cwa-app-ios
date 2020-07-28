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

struct BeMobileTestId {
	let id:String				// R1. This is a string because it can start with 0
	let checksum:String					// 2 digits to suffix to R1 to make (R1|checksum) % 97 == 0 also a string because of 0 prefix possible (and we don't need to do calculations on these numbers individually)

	// Components used to calculate mobile test id
	let randomString:String				// R0
	let secretKey:SymmetricKey			// K
	let datePatientInfectious:String    // t0
	
	let creationDate:Date

	var fullString:String {
		let part1 = id[0...5]
		let part2 = id[5...10]
		let part3 = id[10...15]
		
		return "\(part1)-\(part2)-\(part3)-\(checksum)"
	}
	
	// the string used as registrationToken in the networking calls to fetch the test result
	var registrationToken:String {
		get {
			return "\(id)|\(datePatientInfectious)"
		}
	}

	// this is the t0 date, in YYYY-MM-DD format
	init(datePatientInfectious:String) {
		
		if datePatientInfectious.dateWithoutTime() == nil {
			preconditionFailure("Wrong format")
		}
		
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
		checksum = String.init(format:"%02d",Self.calculateCheckDigits(R1:Int(id)!))
		
		creationDate = Date()
	}
}

extension BeMobileTestId {
	private static func generateK() -> SymmetricKey {
		let K = SymmetricKey(size:.bits128)
		K.withUnsafeBytes{ bytes in
			let data = Data.init(bytes: bytes.baseAddress!, count: bytes.count)
			print("K = \(data.base64EncodedString())")
		}

		return K
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
	
	private static func calculateCheckDigits(R1:Int) -> Int {
		let mod = R1 * 100 % 97
		
		return 97 - mod
	}
}

extension BeMobileTestId {
}

extension BeMobileTestId : Codable {

}

