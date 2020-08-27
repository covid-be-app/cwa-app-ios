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

enum BEAppStrings {
	
	static let currentLanguage = NSLocalizedString("BELanguage", comment: "") == "BELanguage" ? "en" : NSLocalizedString("BELanguage", comment: "")  // :TEMP:

	enum BEExposureSubmission {
		static let symptomsTitle = NSLocalizedString("BEExposureSubmission_symptomsTitle", comment: "")
		static let symptomsExplanation = NSLocalizedString("BEExposureSubmission_symptomsExplanation", comment: "")
		static let yes = NSLocalizedString("BEExposureSubmission_yes", comment: "")
		static let no = NSLocalizedString("BEExposureSubmission_no", comment: "")
		static let cancel = NSLocalizedString("BEExposureSubmission_cancel", comment: "")
	}
	
	enum BEMobileTestId {
		static let title = NSLocalizedString("BEMobileTestId_title", comment: "")
		static let select = NSLocalizedString("BEMobileTestId_Select", comment: "")

		static let save = NSLocalizedString("BEMobileTestId_Save", comment: "")
		static let saveExplanation = NSLocalizedString("BEMobileTestId_saveExplanation", comment: "")
	}

	enum BESelectSymptomsDate {
		static let selectDateTitle = NSLocalizedString("BESelectSymptomsDate_title", comment: "")
		static let dateExplanation = NSLocalizedString("BESelectSymptomsDate_explanation", comment: "")
		static let next = NSLocalizedString("BESelectSymptomsDate_next", comment: "")
	}

	enum BESelectKeyCountries {
		static let title = NSLocalizedString("BESelectKeyCountries_title", comment: "")
		static let explanation = NSLocalizedString("BESelectKeyCountries_explanation", comment: "")
		static let sendKeys = NSLocalizedString("BESelectKeyCountries_sendKeys", comment: "")
	}
	
	enum BEExposureDetection {
		static let offShort = NSLocalizedString("BEExposureDetection_OffShort", comment: "")
	}
	
}
