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

import Foundation

extension URLSession {
	class func coronaWarnSession() -> URLSession {
		#if DISABLE_CERTIFICATE_PINNING
		//Disable certificate pinning while app is running on:
		//Community, Debug, TestFlight, UITesting modes
		let coronaWarnURLSessionDelegate: CoronaWarnURLSessionDelegate? = nil
		#else
		let coronaWarnURLSessionDelegate = CoronaWarnURLSessionDelegate(
			publicKeyHash: "f512d8930ed4c694f2dff50cc4751e3b5326657498d4eadce06d5f6722522452"
		)
		#endif
		return URLSession(
			configuration: .coronaWarnSessionConfiguration(),
			delegate: coronaWarnURLSessionDelegate,
			delegateQueue: .main
		)
		
	}
}
