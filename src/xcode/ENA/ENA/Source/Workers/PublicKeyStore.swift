//
// Corona-Warn-App
//
// SAP SE and all other contributors
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


enum KeyError: Error {
	/// It was not possible to create the base64 encoded data from the public key string
	case encodingError
	/// It was not possible to map the provided bundleID to a matching public key
	case environmentError
	/// It was not possible to read the plist containing the public keys
	case plistError
}

typealias PublicKeyProviding = (String) throws -> PublicKeyProtocol

enum PublicKeyStore {
	static func get(for keyId: String) throws -> PublicKeyProtocol {
		
		if keyId != "be.sciensano.coronalertbe" {
			throw KeyError.environmentError
		}
		
		return PublicKey(with: "qG73R7F3UpqPAzGYTEJxPKC3EnxxfSIX8EbUe/XAcTWLzj4cZ4XOBFrDav7FhSC3NBXkAt1oK5ZI1eRUL8Vv8w==")
	}
}
