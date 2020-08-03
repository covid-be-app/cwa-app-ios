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

struct BECountry : Decodable, Equatable {
	let code3:String
	let name:[String:String]
	var localizedName:String! {
		get {
			return name[BEAppStrings.currentLanguage]!
		}
	}
	
	static func load(_ sortLanguage:String = BEAppStrings.currentLanguage) -> [BECountry] {
		let countriesData = try! Data(contentsOf: Bundle.main.url(forResource: "countries", withExtension: "json")!)
		let decoder = JSONDecoder()
		let countries = try! decoder.decode([BECountry].self, from: countriesData)
		
		return countries.sorted { (country1, country2) -> Bool in
			return country1.name[sortLanguage]!.compare(country2.name[sortLanguage]!) == .orderedAscending
		}
	}
	
	static func == (lhs: BECountry, rhs: BECountry) -> Bool {
		return lhs.code3 == rhs.code3
    }
}

extension Array where Element == BECountry {
	var defaultCountry:BECountry! {
		return self.first { country -> Bool in
			return country.code3 == "BEL"
		}!
	}
}

