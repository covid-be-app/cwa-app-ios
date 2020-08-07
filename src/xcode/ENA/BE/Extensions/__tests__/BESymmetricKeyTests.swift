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
import CryptoKit

@testable import ENA

class BESymmetricKeyTests: XCTestCase {

    func testEncoding() throws {
        let key = SymmetricKey(size:.bits128)
		let encoder = JSONEncoder()
		let decoder = JSONDecoder()
		let encoded = try encoder.encode(key)
		let decoded = try decoder.decode(SymmetricKey.self, from: encoded)
		
		key.withUnsafeBytes{ originalBytes in
			decoded.withUnsafeBytes{ decodedBytes in
				XCTAssertEqual(originalBytes.count, decodedBytes.count)
				
				for x in 0..<originalBytes.count {
					XCTAssertEqual(originalBytes[x],decodedBytes[x])
				}
			}
		}
		
    }
}
