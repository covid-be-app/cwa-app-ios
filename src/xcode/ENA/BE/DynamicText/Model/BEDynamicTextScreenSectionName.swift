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

/// Make sure these stay in sync with the JSON
enum BEDynamicTextScreenSectionName: String, Decodable, CodingKey {
	case explanation = "explanation"
	case pleaseNote = "pleaseNote"
	case otherInformation = "otherInformation"
	case preventiveMeasures = "preventiveMeasures"
	case list = "list"
}
