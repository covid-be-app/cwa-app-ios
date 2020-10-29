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

struct BEDynamicText {
	let structure: [BEDynamicTextScreenName:[BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]]
	let texts:[BEDynamicTextLanguage:[String:String]]

	enum CodingKeys: String, CodingKey {
        case structure
		case texts
    }
}


/// If Swift would support string enums in dictionary keys we wouldn't have to implement all this ...

extension BEDynamicTextLanguage: CodingKey {
	
}

extension BEDynamicTextScreenName: CodingKey {
	
}

extension BEDynamicText: Decodable {

	init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let structureContainer = try container.nestedContainer(keyedBy: BEDynamicTextScreenName.self, forKey: .structure)

        var structureDictionary = [BEDynamicTextScreenName: [BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]]()
		
        for enumKey in structureContainer.allKeys {
            guard let screenName = BEDynamicTextScreenName(rawValue: enumKey.rawValue) else {
                let context = DecodingError.Context(codingPath: [], debugDescription: "Could not parse json key to a BEDynamicTextScreenName object")
                throw DecodingError.dataCorrupted(context)
            }
            let value = try structureContainer.decode([String:[BEDynamicTextScreenSection]].self, forKey: enumKey)
			var convertedValue = [BEDynamicTextScreenSectionName:[BEDynamicTextScreenSection]]()
			
			try value.keys.forEach{ key in
				guard let enumKey = BEDynamicTextScreenSectionName(rawValue: key) else {
					let context = DecodingError.Context(codingPath: [], debugDescription: "Could not parse json key to a BEDynamicTextScreenSectionName object")
					throw DecodingError.dataCorrupted(context)
				}
				guard let keyValue = value[key] else {
					let context = DecodingError.Context(codingPath: [], debugDescription: "Cast error")
					throw DecodingError.dataCorrupted(context)
				}
				convertedValue[enumKey] = keyValue
			}
			
            structureDictionary[screenName] = convertedValue
        }
		
        self.structure = structureDictionary
		
		let textContainer = try container.nestedContainer(keyedBy: BEDynamicTextLanguage.self, forKey: .texts)
        var textDictionary = [BEDynamicTextLanguage: [String:String]]()
		
        for enumKey in textContainer.allKeys {
            guard let languageName = BEDynamicTextLanguage(rawValue: enumKey.rawValue) else {
                let context = DecodingError.Context(codingPath: [], debugDescription: "Could not parse json key to a BEDynamicTextLanguage object")
                throw DecodingError.dataCorrupted(context)
            }
			
            let value = try textContainer.decode([String:String].self, forKey: enumKey)
            textDictionary[languageName] = value
        }
		
		self.texts = textDictionary
    }
}
