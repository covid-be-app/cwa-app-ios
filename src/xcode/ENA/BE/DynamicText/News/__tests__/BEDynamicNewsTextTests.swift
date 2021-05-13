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

class BEDynamicNewsTextTests: XCTestCase {

	private let stubURL = URL(string: "https://www.coronalert.be")!

	private func createDynamicTextService(_ filename: String) -> BEDynamicNewsTextService {
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: filename, withExtension: "json")!
		
		return BEDynamicNewsTextService(bundleURL: url)
	}
	
	private func loadDynamicText(_ filename: String) -> BEDynamicText {
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: filename, withExtension: "json")!
		let decoder = JSONDecoder()
		do {
			let data = try Data(contentsOf: url)
			let result = try decoder.decode(BEDynamicText.self, from: data)
			return result
		} catch {
			fatalError("Something went wrong \(error.localizedDescription)")
		}
	}
	
	override class func tearDown() {
		BEDynamicNewsTextService().deleteCachedFile()
	}
	
	/// test the texts in the bundle
	func testLoadTexts() throws {
		let url = Bundle.main.url(forResource: "dynamicNews", withExtension: "json")!
		let data = try Data(contentsOf: url)
	
		let decoder = JSONDecoder()

		XCTAssertNotNil(try decoder.decode(BEDynamicText.self, from: data))
	}
	
	func testMissingLanguage() throws {
		let dynamicText = loadDynamicText("missingLanguageNewsDynamicTexts")
		XCTAssertThrowsError(try BEDynamicNewsTextService().validateLoadedText(dynamicText))
	}

	func testMissingScreen() throws {
		let dynamicText = loadDynamicText("missingScreensNewsDynamicTexts")
		XCTAssertThrowsError(try BEDynamicNewsTextService().validateLoadedText(dynamicText))
	}

	func testWrongStructure() throws {
		let dynamicText = loadDynamicText("wrongStructureNewsDynamicTexts")
		XCTAssertThrowsError(try BEDynamicNewsTextService().validateLoadedText(dynamicText))
	}

	func testLoadScreen() throws {
		BEDynamicNewsTextService().deleteCachedFile()
		let service = createDynamicTextService("testNewsDynamicTexts")
		XCTAssertEqual(service.newsTitle(), "Your general practitioner blablabla")
	}
	
	/// Test that the texts keep on working after a download error
	func testDownloadTextsWithError() throws {
		BEDynamicNewsTextService().deleteCachedFile()
		let client = ClientMock()
		let service = createDynamicTextService("testNewsDynamicTexts")
		let downloader = BEDynamicTextDownloadService(client: client, textService: service, url: stubURL)
		let expectation = self.expectation(description: "finished")

		downloader.downloadTextsIfNeeded {
			XCTAssertEqual(service.newsTitle(), "Your general practitioner blablabla")
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 0.2)
	}

	/// Test that the texts keep on working after a download of non-JSON data
	func testDownloadTextsCorruptData() throws {
		BEDynamicNewsTextService().deleteCachedFile()
		let client = ClientMock()
		let service = createDynamicTextService("testNewsDynamicTexts")
		let downloader = BEDynamicTextDownloadService(client: client, textService: service, url: stubURL)
		let expectation = self.expectation(description: "finished")
		
		client.dynamicTextsDownloadData = Data()

		downloader.downloadTextsIfNeeded {
			XCTAssertEqual(service.newsTitle(), "Your general practitioner blablabla")
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 0.2)
	}

	/// Test that the texts are updated after a download
	func testDownloadTexts() throws {
		BEDynamicNewsTextService().deleteCachedFile()
		let client = ClientMock()
		let service = createDynamicTextService("testNewsDynamicTexts")
		let downloader = BEDynamicTextDownloadService(client: client, textService: service, url: stubURL, textOutdatedTimeInterval: 1)
		let expectation = self.expectation(description: "finished")
		
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: "testDownloadedNewsTexts", withExtension: "json")!

		client.dynamicTextsDownloadData = try Data(contentsOf: url)

		downloader.downloadTextsIfNeeded {
			XCTAssertEqual(service.newsTitle(), "Downloaded title")
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 0.2)
	}
	
	/// Test that the texts are not updated after a download which does not contain all screens
	func testDownloadMissingTexts() throws {
		BEDynamicNewsTextService().deleteCachedFile()
		let client = ClientMock()
		let service = createDynamicTextService("testNewsDynamicTexts")
		let downloader = BEDynamicTextDownloadService(client: client, textService: service, url: stubURL, textOutdatedTimeInterval: 1)
		let expectation = self.expectation(description: "finished")
		
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: "missingScreensNewsDynamicTexts", withExtension: "json")!

		client.dynamicTextsDownloadData = try Data(contentsOf: url)

		downloader.downloadTextsIfNeeded {
			XCTAssertEqual(service.newsTitle(), "Your general practitioner blablabla")
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 0.2)
	}
	
	/// Test that the texts are downloaded, cached and that a new instance uses the cached version
	func testDownloadAndUseCache() throws {
		BEDynamicNewsTextService().deleteCachedFile()
		let client = ClientMock()
		var service = createDynamicTextService("testNewsDynamicTexts")
		let downloader = BEDynamicTextDownloadService(client: client, textService: service, url: stubURL, textOutdatedTimeInterval: 1)
		let expectation = self.expectation(description: "finished")
		
		XCTAssertEqual(service.newsTitle(), "Your general practitioner blablabla")
		
		let testBundle = Bundle(for: type(of: self))
		let url = testBundle.url(forResource: "testDownloadedNewsTexts", withExtension: "json")!

		client.dynamicTextsDownloadData = try Data(contentsOf: url)

		downloader.downloadTextsIfNeeded {
			XCTAssertEqual(service.newsTitle(), "Downloaded title")
			service = self.createDynamicTextService("testNewsDynamicTexts")
			XCTAssertEqual(service.newsTitle(), "Downloaded title")
			expectation.fulfill()
		}
		
		waitForExpectations(timeout: 2)
	}
	
	/// Test that corrupting the cached file will reuse the file from the bundle
	func testCorruptCache() throws {
		BEDynamicNewsTextService().corruptCache()
		let service = createDynamicTextService("testNewsDynamicTexts")
		XCTAssertEqual(service.newsTitle(), "Your general practitioner blablabla")
	}
}
