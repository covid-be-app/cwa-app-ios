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
enum BEDynamicTextScreenName: String, Decodable, CaseIterable {
	case standard = "standard"
	case highRisk = "highRisk"
	case positiveTestResultCard = "positiveTestResultCard"
	case positiveTestResult = "positiveTestResult"
	case negativeTestResult = "negativeTestResult"
	case thankYou = "thankYou"
}

