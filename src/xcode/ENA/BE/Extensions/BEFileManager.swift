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

extension FileManager {
	func applicationSupportURL(_ file: String? = nil) -> URL {
		let urls = self.urls(for: .applicationSupportDirectory, in: .userDomainMask)
		let applicationSupportURL = urls[0]
		
		if let filePath = file {
			return applicationSupportURL.appendingPathComponent(filePath)
		}
		
		return applicationSupportURL
	}
	
	func removeTemporaryDirectoryContents() throws {
		let tempDir = self.temporaryDirectory
		let contents = try self.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
		try contents.forEach { item in
			try self.removeItem(at: item)
		}
	}
}
