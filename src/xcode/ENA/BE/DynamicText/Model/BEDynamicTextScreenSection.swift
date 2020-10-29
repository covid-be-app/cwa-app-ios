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
import UIKit

struct BEDynamicTextScreenSection : Decodable {
	let icon:UIImage?
	var title:String?
	var text:String?
	var paragraphs:[String]?
	
    enum CodingKeys: String, CodingKey {
        case icon
        case title
        case text
		case paragraphs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
		title = try? container.decode(String.self, forKey: .title)
        text = try? container.decode(String.self, forKey: .text)
        paragraphs = try? container.decode([String].self, forKey: .paragraphs)
		
		if let iconTitle = try? container.decode(String.self, forKey: .icon) {
			icon = UIImage(named: iconTitle)
		} else {
			icon = nil
		}
    }
	
	func translate(_ translationDict: [String:String]) -> BEDynamicTextScreenSection {
		var result = self
		
		if let title = self.title {
			result.title = translationDict[title] ?? title
		}
		
		if let text = self.text {
			result.text = translationDict[text] ?? text
		}
		
		if let paragraphs = self.paragraphs {
			result.paragraphs = paragraphs.map{ translationDict[$0] ?? $0 }
		}
		
		return result
	}
}
