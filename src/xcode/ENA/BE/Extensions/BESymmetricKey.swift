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

extension SymmetricKey : Codable {
	enum CodingKeys: CodingKey {
		case base64Data
	}
	
	public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
		
		let base64Data = try values.decode(String.self, forKey: .base64Data)
		let data = Data(base64Encoded: base64Data)!
		
		self.init(data: data)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try self.withUnsafeBytes{ bytes in
			let dataString = Data(bytes).base64EncodedString()
			
			try container.encode(dataString, forKey: .base64Data)
		}
	}
}
