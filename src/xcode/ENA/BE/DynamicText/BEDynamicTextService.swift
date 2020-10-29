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
	static let cacheURL = FileManager.default.applicationSupportURL("dynamicTexts.json")
	static let defaultBundleURL = Bundle.main.url(forResource: "dynamicTexts", withExtension: "json")!

	var dynamicText:BEDynamicText!
	var bundleURL: URL!
	
	// if this throws there is a big issue with the data stored inside the bundle
	init(_ defaultFileURL:URL = defaultBundleURL) {
		bundleURL = defaultFileURL
		
		do {
			try copyBundleToCacheIfMoreRecent()
			dynamicText = try Self.loadTextFromCache()
			return
		} catch {
			logError(message: "\(error.localizedDescription)")
		}

		// if that fails, copy the data in the bundle and try again
		do {
			try copyBundleTextsToCache()
			dynamicText = try Self.loadTextFromCache()
		} catch {
			logError(message: "\(error.localizedDescription)")
			fatalError("Should never happen")
		}
	}
	
	func updateTexts(_ data: Data) throws {
		if let text = try? Self.loadTextFromData(data) {
			do {
				try data.write(to: Self.cacheURL, options: .atomic)
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
	
	static func validateLoadedText(_ dynamicText: BEDynamicText) throws {
		try BEDynamicTextLanguage.allCases.forEach{ language in
			if dynamicText.texts[language] == nil {
				logError(message: "Missing language \(language)")
				throw BEDynamicTextServiceError.missingLanguage
			}
		}
		
		try BEDynamicTextScreenName.allCases.forEach{ screenName in
			if dynamicText.structure[screenName] == nil {
				logError(message: "Missing screen \(screenName)")
				throw BEDynamicTextServiceError.missingScreen
			}
		}

		guard
			let standard = dynamicText.structure[.standard],
			let highRisk = dynamicText.structure[.highRisk],
			let positiveTestResultCard = dynamicText.structure[.positiveTestResultCard],
			let positiveTestResult = dynamicText.structure[.positiveTestResult],
			let negativeTestResult = dynamicText.structure[.negativeTestResult],
			let thankYou = dynamicText.structure[.thankYou] else {
				throw BEDynamicTextServiceError.missingScreen
		}
		
		try validateRiskScreen(standard)
		try validateRiskScreen(highRisk)
		try validatePositiveTestResultCard(positiveTestResultCard)
		try validateTestResult(positiveTestResult)
		try validateTestResult(negativeTestResult)
		try validateThankYou(thankYou)
	}
	
	private func copyBundleToCacheIfMoreRecent() throws {
		let sourceAttributes = try FileManager.default.attributesOfItem(atPath: bundleURL.path)
		let cacheAttributes = try FileManager.default.attributesOfItem(atPath: Self.cacheURL.path)

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
		
		try data.write(to: Self.cacheURL, options: .atomic)
		
		// also copy the modification date
		let sourceAttributes = try FileManager.default.attributesOfItem(atPath: bundleURL.path)
		var destinationAttributes = try FileManager.default.attributesOfItem(atPath: Self.cacheURL.path)

		guard let modificationDate = sourceAttributes[.modificationDate] as? Date else {
			throw BEDynamicTextServiceError.cachingError
		}
		
		destinationAttributes[.modificationDate] = modificationDate

		try FileManager.default.setAttributes(destinationAttributes, ofItemAtPath: Self.cacheURL.path)
	}
	
	static private func loadTextFromCache() throws -> BEDynamicText {
		log(message: "Load text from cache")
		let data = try Data(contentsOf: Self.cacheURL)

		return try loadTextFromData(data)
	}
	
	static private func loadTextFromData(_ data: Data) throws -> BEDynamicText {
		let decoder = JSONDecoder()
		let result = try decoder.decode(BEDynamicText.self, from: data)
		
		// do some sanity checks
		try Self.validateLoadedText(result)
		
		return result
	}
	
	static private func validateRiskScreen(_ screen:[BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]) throws {
		guard let preventiveMeasures = screen[.preventiveMeasures] else {
			throw BEDynamicTextServiceError.missingScreenSection
		}
		
		try preventiveMeasures.forEach{ entry in
			if entry.icon == nil || entry.text == nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}
			
			if entry.title != nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}
		}
	}
	
	static private func validatePositiveTestResultCard(_ screen:[BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]) throws {
		guard let explanation = screen[.explanation] else {
			throw BEDynamicTextServiceError.missingScreenSection
		}
		
		try explanation.forEach{ entry in
			if entry.icon == nil || entry.text == nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}

			if entry.title != nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}

			if entry.paragraphs != nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}
		}
	}

	static private func validateTestResult(_ screen:[BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]) throws {
		guard let explanation = screen[.explanation] else {
			throw BEDynamicTextServiceError.missingScreenSection
		}
		
		try explanation.forEach{ entry in
			if entry.icon == nil || entry.text == nil || entry.title == nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}
		}
	}
	
	static private func validateThankYou(_ screen:[BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]) throws {
		guard
			let pleaseNote = screen[.pleaseNote],
			let otherInformation = screen[.otherInformation] else {
				throw BEDynamicTextServiceError.missingScreenSection
		}
		
		try pleaseNote.forEach{ entry in
			if entry.icon == nil || entry.text == nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}

			if entry.title != nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}

			if entry.paragraphs != nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}
		}
		
		try otherInformation.forEach{ entry in
			if entry.icon != nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}
			if entry.text != nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}
			if entry.title != nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}
			if entry.paragraphs == nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}
		}
	}
}
