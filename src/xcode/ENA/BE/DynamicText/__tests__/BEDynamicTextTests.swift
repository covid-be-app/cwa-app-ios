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

import XCTest
@testable import ENA

class BEDynamicTextTests: XCTestCase {

	private func createDynamicTextService(_ filename: String) -> BEDynamicTextService {
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: filename, withExtension: "json")!
		
		return BEDynamicTextService(url)
	}
	
	private func loadDynamicText(_ filename: String) -> BEDynamicText {
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: filename, withExtension: "json")!
		let decoder = JSONDecoder()
		let data = try! Data(contentsOf: url)
		let result = try! decoder.decode(BEDynamicText.self, from: data)
		
		return result
	}
	
	private func getFirstScreenSectionEntry(service:BEDynamicTextService, name: BEDynamicTextScreenName, section: BEDynamicTextScreenSectionName, language:BEDynamicTextLanguage = .current) -> BEDynamicTextScreenSection {
		let screen = service.screen(name, language: language)
		XCTAssertNotNil(screen[section])
		XCTAssertNotNil(screen[section]![0])

		return screen[.preventiveMeasures]![0]
	}
	
	override class func tearDown() {
		BEDynamicTextService.deleteCachedFile()
	}
	
	/// test the texts in the bundle
	func testLoadTexts() throws {
		let url = Bundle.main.url(forResource: "dynamicTexts", withExtension: "json")!
		let data = try Data(contentsOf: url)
	
		let decoder = JSONDecoder()

		XCTAssertNotNil(try decoder.decode(BEDynamicText.self, from: data))
	}
	
	func testMissingLanguage() throws {
		let dynamicText = loadDynamicText("missingLanguageDynamicTexts")
		XCTAssertThrowsError(try BEDynamicTextService.validateLoadedText(dynamicText))
	}

	func testMissingScreen() throws {
		let dynamicText = loadDynamicText("missingScreensDynamicTexts")
		XCTAssertThrowsError(try BEDynamicTextService.validateLoadedText(dynamicText))
	}

	func testWrongStructure() throws {
		let dynamicText = loadDynamicText("wrongStructureDynamicTexts")
		XCTAssertThrowsError(try BEDynamicTextService.validateLoadedText(dynamicText))
	}

	func testLoadScreen() throws {
		BEDynamicTextService.deleteCachedFile()
		let service = createDynamicTextService("testDynamicTexts")
		let sectionEntry = getFirstScreenSectionEntry(service: service, name: .highRisk, section: .preventiveMeasures)
		XCTAssertEqual(sectionEntry.text, "If possible, please go home and stay at home.")
	}
	
	/// Test that the texts keep on working after a download error
	func testDownloadTextsWithError() throws {
		BEDynamicTextService.deleteCachedFile()
		let client = ClientMock()
		let service = createDynamicTextService("testDynamicTexts")
		let downloader = BEDynamicTextDownloadService(client: client, textService: service)
		let expectation = self.expectation(description: "finished")

		downloader.downloadTextsIfNeeded {
			let sectionEntry = self.getFirstScreenSectionEntry(service: service, name: .highRisk, section: .preventiveMeasures)
			XCTAssertEqual(sectionEntry.text, "If possible, please go home and stay at home.")
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 0.2)
	}

	/// Test that the texts keep on working after a download of non-JSON data
	func testDownloadTextsCorruptData() throws {
		BEDynamicTextService.deleteCachedFile()
		let client = ClientMock()
		let service = createDynamicTextService("testDynamicTexts")
		let downloader = BEDynamicTextDownloadService(client: client, textService: service)
		let expectation = self.expectation(description: "finished")
		
		client.dynamicTextsDownloadData = Data()

		downloader.downloadTextsIfNeeded {
			let sectionEntry = self.getFirstScreenSectionEntry(service: service, name: .highRisk, section: .preventiveMeasures)
			XCTAssertEqual(sectionEntry.text, "If possible, please go home and stay at home.")
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 0.2)
	}

	/// Test that the texts are updated after a download
	func testDownloadTexts() throws {
		BEDynamicTextService.deleteCachedFile()
		let client = ClientMock()
		let service = createDynamicTextService("testDynamicTexts")
		let downloader = BEDynamicTextDownloadService(client: client, textService: service, textOutdatedTimeInterval: 1)
		let expectation = self.expectation(description: "finished")
		
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: "testDownloadedTexts", withExtension: "json")!

		client.dynamicTextsDownloadData = try Data(contentsOf: url)

		downloader.downloadTextsIfNeeded {
			let englishSectionEntry = self.getFirstScreenSectionEntry(service: service, name: .highRisk, section: .preventiveMeasures, language: .english)
			let frenchSectionEntry = self.getFirstScreenSectionEntry(service: service, name: .highRisk, section: .preventiveMeasures, language: .french)
			XCTAssertEqual(englishSectionEntry.text, "If possible, hide on the moon.")
			XCTAssertEqual(frenchSectionEntry.text, "Si possible, cachez-vous sur la lune.")
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 0.2)
	}
	
	/// Test that the texts are not updated after a download which does not contain all screens
	func testDownloadMissingTexts() throws {
		BEDynamicTextService.deleteCachedFile()
		let client = ClientMock()
		let service = createDynamicTextService("testDynamicTexts")
		let downloader = BEDynamicTextDownloadService(client: client, textService: service, textOutdatedTimeInterval: 1)
		let expectation = self.expectation(description: "finished")
		
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: "missingScreensDynamicTexts", withExtension: "json")!

		client.dynamicTextsDownloadData = try Data(contentsOf: url)

		downloader.downloadTextsIfNeeded {
			let sectionEntry = self.getFirstScreenSectionEntry(service: service, name: .highRisk, section: .preventiveMeasures)
			XCTAssertEqual(sectionEntry.text, "If possible, please go home and stay at home.")
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 0.2)
	}
	
	/// Test that the texts are downloaded, cached and that a new instance uses the cached version
	func testDownloadAndUseCache() throws {
		BEDynamicTextService.deleteCachedFile()
		let client = ClientMock()
		let service = createDynamicTextService("testDynamicTexts")
		let downloader = BEDynamicTextDownloadService(client: client, textService: service, textOutdatedTimeInterval: 1)
		let expectation = self.expectation(description: "finished")
		
		let sectionEntry = getFirstScreenSectionEntry(service: service, name: .highRisk, section: .preventiveMeasures)
		XCTAssertEqual(sectionEntry.text, "If possible, please go home and stay at home.")

		
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: "testDownloadedTexts", withExtension: "json")!

		client.dynamicTextsDownloadData = try Data(contentsOf: url)

		downloader.downloadTextsIfNeeded {
			let sectionEntry = self.getFirstScreenSectionEntry(service: service, name: .highRisk, section: .preventiveMeasures, language: .english)
			XCTAssertEqual(sectionEntry.text, "If possible, hide on the moon.")
			
			let service = self.createDynamicTextService("testDynamicTexts")
			let sectionEntryFromCache = self.getFirstScreenSectionEntry(service: service, name: .highRisk, section: .preventiveMeasures, language: .english)

			XCTAssertEqual(sectionEntryFromCache.text, "If possible, hide on the moon.")

			
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 2)
	}
	
	/// Test that corrupting the cached file will reuse the file from the bundle
	func testCorruptCache() throws {
		BEDynamicTextService.corruptCache()
		let service = createDynamicTextService("testDynamicTexts")
		let sectionEntry = getFirstScreenSectionEntry(service: service, name: .highRisk, section: .preventiveMeasures)
		XCTAssertEqual(sectionEntry.text, "If possible, please go home and stay at home.")
	}
}


extension BEDynamicTextService {
	static func deleteCachedFile() {
		do {
			try FileManager.default.removeItem(at: cacheURL)
		} catch {
			logError(message: "\(error.localizedDescription)")
		}
	}

	static func corruptCache() {
		do {
			let data = "hahahaha".data(using: .utf8)!
			try data.write(to: cacheURL)
		} catch {
			logError(message: "\(error.localizedDescription)")
		}
	}
}
