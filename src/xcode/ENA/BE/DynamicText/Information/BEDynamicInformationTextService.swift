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

private let defaultCacheURL = FileManager.default.applicationSupportURL("dynamicTextsV2.json")
private let defaultBundleURL = Bundle.main.url(forResource: "dynamicTextsV2", withExtension: "json")!

class BEDynamicInformationTextService: BEDynamicTextService {

	override init(cacheURL: URL = defaultCacheURL, bundleURL: URL = defaultBundleURL) {
		super.init(cacheURL: cacheURL, bundleURL: bundleURL)
	}
	
	override func validateLoadedText(_ dynamicText: BEDynamicText) throws {
		let screenNames: [BEDynamicTextScreenName] = [.standard, .highRisk, .positiveTestResultCard, .positiveTestResult, .negativeTestResult, .thankYou, .participatingCountries]

		try super.validateLoadedText(dynamicText, screenNames: screenNames)
	}
		
	override func validateScreenStructure(name: BEDynamicTextScreenName, structure: [BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]) throws {
		switch name {
		case .standard:
			try Self.validateRiskScreen(structure)
		case .highRisk:
			try Self.validateRiskScreen(structure)
		case .positiveTestResultCard:
			try Self.validatePositiveTestResultCard(structure)
		case .positiveTestResult:
			try Self.validateTestResult(structure)
		case .negativeTestResult:
			try Self.validateTestResult(structure)
		case .thankYou:
			try Self.validateThankYou(structure)
		case .participatingCountries:
			try Self.validateParticipatingCountries(structure)
		default:
			break
		}
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
	
	static private func validateParticipatingCountries(_ screen:[BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]) throws {
		guard let list = screen[.list] else {
			throw BEDynamicTextServiceError.missingScreenSection
		}
		
		try list.forEach{ entry in
			if entry.icon == nil {
				throw BEDynamicTextServiceError.wrongSectionFields
			}
			if entry.text == nil {
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
}

