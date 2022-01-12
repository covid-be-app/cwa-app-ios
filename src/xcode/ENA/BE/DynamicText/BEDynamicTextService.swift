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

enum BEDynamicTextServiceError: Error {
	case cachingError
	case missingLanguage
	case missingScreen
	case missingScreenSection
	case wrongSectionFields
}

class BEDynamicTextService {
	var dynamicText:BEDynamicText!
	
	private let bundleURL: URL
	let cacheURL: URL
	
	// if this throws there is a big issue with the data stored inside the bundle
	init(cacheURL: URL, bundleURL: URL) {
		self.cacheURL = cacheURL
		self.bundleURL = bundleURL
		
		do {
			try copyBundleToCacheIfMoreRecent()
			dynamicText = try loadTextFromCache()
			return
		} catch {
			logError(message: "\(error.localizedDescription)")
		}

		// if that fails, copy the data in the bundle and try again
		do {
			try copyBundleTextsToCache()
			dynamicText = try loadTextFromCache()
		} catch {
			logError(message: "\(error.localizedDescription)")
			fatalError("Should never happen")
		}
	}
	
	func updateTexts(_ data: Data) throws {
		if let text = try? loadTextFromData(data) {
			do {
				try data.write(to: cacheURL, options: .atomic)
				dynamicText = text
			} catch {
			}
		} else {
			logError(message: "Failed updating text")
		}
	}
	
	func screen(_ screenName: BEDynamicTextScreenName, language: BEDynamicTextLanguage = .current) -> [BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]] {
		guard
			let screen = dynamicText.structure[screenName],
			let translations = dynamicText.texts[language] else {
			fatalError("Should never happen")
		}

		let returnValue = screen.mapValues{ sections in
			return sections.map{ $0.translate(translations) }
		}
		
		return returnValue
	}
	
	func sections(_ screenName: BEDynamicTextScreenName, section: BEDynamicTextScreenSectionName,language: BEDynamicTextLanguage = .current) -> [BEDynamicTextScreenSection] {
		let dynamicScreen = screen(screenName, language: language)
		guard
			let dynamicSections: [BEDynamicTextScreenSection] = dynamicScreen[section] else {
			fatalError("Should never happen")
		}

		return dynamicSections
	}
	
	private func copyBundleToCacheIfMoreRecent() throws {
		let sourceAttributes = try FileManager.default.attributesOfItem(atPath: bundleURL.path)
		let cacheAttributes = try FileManager.default.attributesOfItem(atPath: cacheURL.path)

		guard
			let sourceModificationDate = sourceAttributes[.modificationDate] as? Date,
			let destinationModificationDate = cacheAttributes[.modificationDate] as? Date else {
			throw BEDynamicTextServiceError.cachingError
		}
		
		if sourceModificationDate > destinationModificationDate {
			log(message:"Bundle file is more recent than cache. Overwriting cache")
			try copyBundleTextsToCache()
		}
	}
	
	private func copyBundleTextsToCache() throws {
		log(message: "Copy text to cache")
		guard
			let data = try? Data(contentsOf: bundleURL)
		else {
			fatalError("Should never happen")
		}
		
		try data.write(to: cacheURL, options: .atomic)
		
		// also copy the modification date
		let sourceAttributes = try FileManager.default.attributesOfItem(atPath: bundleURL.path)
		var destinationAttributes = try FileManager.default.attributesOfItem(atPath: cacheURL.path)

		guard let modificationDate = sourceAttributes[.modificationDate] as? Date else {
			throw BEDynamicTextServiceError.cachingError
		}
		
		destinationAttributes[.modificationDate] = modificationDate

		try FileManager.default.setAttributes(destinationAttributes, ofItemAtPath: cacheURL.path)
	}
	
	private func loadTextFromCache() throws -> BEDynamicText {
		let data = try Data(contentsOf: cacheURL)

		return try loadTextFromData(data)
	}
	
	private func loadTextFromData(_ data: Data) throws -> BEDynamicText {
		let decoder = JSONDecoder()
		let result = try decoder.decode(BEDynamicText.self, from: data)
		
		// do some sanity checks
		try validateLoadedText(result)
		
		return result
	}
	
	func validateLoadedText(_ dynamicText: BEDynamicText) throws {
		fatalError("Override in subclass")
	}
	
	func validateLoadedText(_ dynamicText: BEDynamicText, screenNames: [BEDynamicTextScreenName]) throws {
		try BEDynamicTextLanguage.allCases.forEach{ language in
			if dynamicText.texts[language] == nil {
				logError(message: "Missing language \(language)")
				throw BEDynamicTextServiceError.missingLanguage
			}
		}
		
		try screenNames.forEach{ screenName in
			guard let structure = dynamicText.structure[screenName] else {
				logError(message: "Missing screen \(screenName)")
				throw BEDynamicTextServiceError.missingScreen
			}
			
			try validateScreenStructure(name: screenName, structure: structure)
		}
	}
	
	func validateScreenStructure(name: BEDynamicTextScreenName, structure: [BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]) throws {
		fatalError("Override in subclass")
	}
}
