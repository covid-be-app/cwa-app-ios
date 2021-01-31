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

@testable import ENA
import Foundation
import CryptoKit
import ZIPFoundation

// MARK: -  Static helpers for package creation

extension SAPDownloadedPackage {

	/// - note: Will SHA256 hash the data
	static func makeSignature(data: Data, key: PrivateKeyProvider, bundleId: String = "be.sciensano.coronalertbe") throws -> SAP_TEKSignature {
		var signature = SAP_TEKSignature()
		signature.signature = try key.signature(for: data).derRepresentation
		signature.signatureInfo = makeSignatureInfo(bundleId: bundleId)

		return signature
	}

	static func makeSignatureInfo(bundleId: String = "be.sciensano.coronalertbe") -> SAP_SignatureInfo {
		var info = SAP_SignatureInfo()
		info.appBundleID = bundleId

		return info
	}

	static func makePackage(bin: Data, signature: SAP_TEKSignatureList) throws -> SAPDownloadedPackage {
		return SAPDownloadedPackage(
			keysBin: bin,
			signature: try signature.serializedData()
		)
	}

	/// Make a SAPDownloadedPackage with the provided data and signing key
	///
	/// - important: Both data and key are defaulted, but make sure to pass your own key if you want to test the verification process!
	///	Accepting the default key is only useful if you just need a package and do not care about signing validation
	static func makePackage(bin: Data = Data(bytes: [0xA, 0xB, 0xC], count: 3), key: PrivateKeyProvider = CryptoProvider.createPrivateKey()) throws -> SAPDownloadedPackage {
		let signature = try makeSignature(data: bin, key: key).asList()
		return try makePackage(bin: bin, signature: signature)
	}
}

// MARK: - Helpers

extension SAPDownloadedPackage {
	func zipped() throws -> Archive {
		guard let archive = Archive(accessMode: .create) else { throw ArchivingError.creationError }

		try archive.addEntry(with: "export.bin", type: .file, uncompressedSize: UInt32(bin.count), bufferSize: 4, provider: { position, size -> Data in
			return bin.subdata(in: position..<position + size)
		})

		try archive.addEntry(with: "export.sig", type: .file, uncompressedSize: UInt32(signature.count), bufferSize: 4, provider: { position, size -> Data in
			return signature.subdata(in: position..<position + size)
		})

		return archive
	}
}

enum ArchivingError: Error {
	case creationError
}

extension SAP_TEKSignature {
	func asList() -> SAP_TEKSignatureList {
		var signatureList = SAP_TEKSignatureList()
		signatureList.signatures = [self]

		return signatureList
	}
}

extension Array where Element == SAP_TEKSignature {
	func asList() -> SAP_TEKSignatureList {
		var signatureList = SAP_TEKSignatureList()
		signatureList.signatures = self

		return signatureList
	}
}

/// Quick and dirty factory for asymmetric keys
enum CryptoProvider {
	
	/// Create a private signing key
	/// - Returns: The key as `PrivateKeyProvider`
	static func createPrivateKey(useFallback: Bool = false) -> PrivateKeyProvider {
		do {
			return try PrivateKey()
		} catch {
			fatalError(error.localizedDescription) // should not happen™
		}
	}

	/// A public key
	///
	/// - Parameter privateKey: The private key to derive the public key from. If no key is given, the default private key will be created
	/// - Returns:The requested public key
	static func createPublicKey(from privateKey: PrivateKeyProvider? = nil, useFallback: Bool = false) -> PublicKeyProtocol {
		let priv = privateKey ?? createPrivateKey(useFallback: useFallback)
		return PublicKey(rawRepresentation: priv.publicKeyRaw)
	}

	/// Creates a new key pair
	///
	/// - Returns:A tuple containing a private key and it's corresponding public key
	static func createKeyPair(useFallback: Bool = false) -> (PrivateKeyProvider, PublicKeyProtocol) {
		let priv = createPrivateKey(useFallback: useFallback)
		return (priv, PublicKey(rawRepresentation: priv.publicKeyRaw))
	}
}
