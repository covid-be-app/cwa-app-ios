//
// Corona-Warn-App
//
// SAP SE and all other contributors /
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

final class CoronaWarnURLSessionDelegate: NSObject {
	private let publicKeyHash: String

	// MARK: Creating a Delegate
	init(publicKeyHash: String) {
		self.publicKeyHash = publicKeyHash
	}
}

extension CoronaWarnURLSessionDelegate: URLSessionDelegate {
	func urlSession(
		_ session: URLSession,
		didReceive challenge: URLAuthenticationChallenge,
		completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
	) {
		func reject() { completionHandler(.cancelAuthenticationChallenge, /* credential */ nil) }

		// `serverTrust` not nil implies that authenticationMethod == NSURLAuthenticationMethodServerTrust
		guard
			let trust = challenge.protectionSpace.serverTrust
		else {
			// Reject all requests that we do not have a public key to pin for
			reject()
			return
		}

		func accept() { completionHandler(.useCredential, URLCredential(trust: trust)) }

		var secresult = SecTrustResultType.invalid
		let status = SecTrustEvaluate(trust, &secresult)

		if status == errSecSuccess {
			// we expect a chain of at least 2 certificates
			// index '1' is the required intermediate
			if
				let serverCertificate = SecTrustGetCertificateAtIndex(trust, 1),
				let serverPublicKey = SecCertificateCopyKey(serverCertificate),
				let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil ) as Data? {

				// Matching fingerprint?
				let keyHash = serverPublicKeyData.sha256String()
				if publicKeyHash == keyHash {
					// Success! This is our server
					completionHandler(.useCredential, URLCredential(trust: trust))
					return
				}
			} else {
				logError(message: "Could not trust or get certificate, rejecting!")
			}
		}
		
		reject()
	}
}
