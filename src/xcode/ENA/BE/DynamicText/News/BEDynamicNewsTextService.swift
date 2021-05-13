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

private let defaultCacheURL = FileManager.default.applicationSupportURL("dynamicNews.json")
private let defaultBundleURL = Bundle.main.url(forResource: "dynamicNews", withExtension: "json")!

class BEDynamicNewsTextService: BEDynamicTextService {
	static var newsStatusChangedNotificationName = Notification.Name("newsStatusChangedNotificationName")
	
	var hasNews: Bool {
		newsTitle() != nil
	}
	
	override init(cacheURL: URL = defaultCacheURL, bundleURL: URL = defaultBundleURL) {
		super.init(cacheURL: cacheURL, bundleURL: bundleURL)
	}
	
	func newsTitle(language: BEDynamicTextLanguage = .current) -> String? {
		guard
			let screen = dynamicText.structure[.news],
			let sections = screen[.explanation],
			let translations = dynamicText.texts[language] else {
			fatalError("Should never happen")
		}

		let section = sections[0]

		if let title = section.translate(translations).title {
			if title.isEmpty { return nil }
			
			return title
		}
		
		return nil
	}

	func newsText(language: BEDynamicTextLanguage = .current) -> String? {
		guard
			let screen = dynamicText.structure[.news],
			let sections = screen[.explanation],
			let translations = dynamicText.texts[language] else {
			fatalError("Should never happen")
		}

		let section = sections[0]

		if let text = section.translate(translations).text {
			if text.isEmpty { return nil }
			
			return text
		}
		
		return nil
	}

	override func validateLoadedText(_ dynamicText: BEDynamicText) throws {
		let screenNames: [BEDynamicTextScreenName] = [.news]

		try super.validateLoadedText(dynamicText, screenNames: screenNames)
	}

	override func validateScreenStructure(name: BEDynamicTextScreenName, structure: [BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]) throws {
		if name == .news {
			try Self.validateNews(structure)
		}
	}
	
	static private func validateNews(_ screen:[BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]) throws {
		guard let explanations = screen[.explanation] else {
			throw BEDynamicTextServiceError.missingScreenSection
		}
		
		if explanations.isEmpty {
			throw BEDynamicTextServiceError.missingScreenSection
		}

		if explanations.count != 1 {
			throw BEDynamicTextServiceError.wrongSectionFields
		}

		let explanation = explanations[0]
		
		if explanation.icon != nil {
			throw BEDynamicTextServiceError.wrongSectionFields
		}

		if explanation.title == nil {
			throw BEDynamicTextServiceError.wrongSectionFields
		}

		if explanation.text == nil {
			throw BEDynamicTextServiceError.wrongSectionFields
		}
	}


}
