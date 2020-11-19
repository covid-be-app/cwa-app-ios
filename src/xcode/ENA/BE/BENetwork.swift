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
import Network

class BENetwork {
	typealias Completion = (Bool) -> Void
	
	private var pathMonitor: NWPathMonitor!

	func isConnectedToWifi(_ completion: @escaping Completion) {
		pathMonitor = NWPathMonitor()
		
		pathMonitor.pathUpdateHandler = { [weak pathMonitor] path in
			if path.status != .satisfied {
				log(message: "Not connected to network")
				completion(false)
			} else {
				if path.usesInterfaceType(.wifi) {
					log(message: "Connected to wifi")
					completion(true)
				} else {
					log(message: "Not connected to wifi")
					completion(false)
				}
			}
			
			pathMonitor?.cancel()
		}
		
		pathMonitor.start(queue: .main)
	}
}
