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

enum BEEnvironment: String, CaseIterable {
	case production = "production"
	case staging = "staging"
	case test = "test"
	case development = "development"

	func urlSuffix() -> String {
		switch self {
		case .development:
			return "dev"
		case .production:
			return "prd"
		case .staging:
			return "stg"
		case .test:
			return "tst"
		}
	}
	
	static var current: BEEnvironment {
		if let value = Bundle.main.infoDictionary?["BEEnvironment"] as? String {
			guard let environment = BEEnvironment(rawValue: value) else {
				fatalError("Should never happen")
			}
			
			return environment
		}
		
		#if RELEASE
			return .staging
		#else
			return .test
		#endif
	}
}

