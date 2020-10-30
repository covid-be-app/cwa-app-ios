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

class BEDynamicTextDownloadService {
	typealias DynamicTextLoader = () -> Void

	private static

	var dynamicText:BEDynamicText!
	
	private let client: Client
	private var textService: BEDynamicTextService
	private let outdatedTimeInterval: TimeInterval
	
	init(client: Client, textService: BEDynamicTextService, textOutdatedTimeInterval:TimeInterval = .textOutdatedTimeInterval) {
		self.client = client
		self.textService = textService
		self.outdatedTimeInterval = textOutdatedTimeInterval
	}
	
	func downloadTextsIfNeeded(completion: @escaping DynamicTextLoader) {
		if
			let attributes = try? FileManager.default.attributesOfItem(atPath: BEDynamicTextService.cacheURL.path),
			let modificationDate = attributes[.modificationDate] as? Date {
			
				if modificationDate.timeIntervalSinceNow > -self.outdatedTimeInterval {
					DispatchQueue.main.async {
						log(message: "Cached file \(modificationDate) too recent. Will not update")
						completion()
					}
					
					return
				}
		}
		
		downloadTexts(completion)
	}

	/// Download the texts from the server
	/// We ignore errors here in the callback since there isn't much we can do and we'll fallback to the previous version of the text anyway
	private func downloadTexts(_ completion: @escaping DynamicTextLoader) {
		log(message: "Downloading texts")
		client.getDynamicTexts { result in

			/// Since dynamic texts are used from the main thread (UI) we make sure there is no other thread manipulating
			/// files that while they are being read from the main thread.
			DispatchQueue.main.async {
				switch result {
				case .success(let data):
					do {
						try self.textService.updateTexts(data)
						log(message: "Download texts success")
					} catch {
						logError(message: "Failed saving text from server: \(error.localizedDescription)")
					}
				case .failure(let error):
					logError(message: "Failed loading text from server: \(error.localizedDescription)")
				}

				completion()
			}
		}
	}
}

extension TimeInterval {
	static var textOutdatedTimeInterval: TimeInterval {
		switch BEEnvironment.current {
		case .production:
			return TimeInterval(24 * 60 * 60)
		case .staging:
			return TimeInterval(60)
		case .test:
			return TimeInterval(60)
		}
	}
}
