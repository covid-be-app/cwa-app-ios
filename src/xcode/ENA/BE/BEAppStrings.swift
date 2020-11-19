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
	
	static let currentLanguage = NSLocalizedString("BELanguage", comment: "")

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

		static let close = NSLocalizedString("BEMobileTestId_Close", comment: "")
		static let saveExplanation = NSLocalizedString("BEMobileTestId_saveExplanation", comment: "")
		
		static let dateInfectious = NSLocalizedString("BEMobileTestId_dateInfectious", comment: "")
		static let code = NSLocalizedString("BEMobileTestId_code", comment: "")
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
	
	enum BEInfectionSummary {
		static let notAvailable = NSLocalizedString("BENoInfectionSummary_title", comment: "")
		static let title = NSLocalizedString("BEInfectionSummary_title", comment: "")
		static let forWeek = NSLocalizedString("BEInfectionSummary_forWeek", comment: "")
		static let averageInfected = NSLocalizedString("BEInfectionSummary_averageInfected", comment: "")
		static let averageHospitalised = NSLocalizedString("BEInfectionSummary_averageHospitalised", comment: "")
		static let averageDeceased = NSLocalizedString("BEInfectionSummary_averageDeceased", comment: "")
		static let updatedAt = NSLocalizedString("BEInfectionSummary_updatedAt", comment: "")
	}
	
	enum BERiskLegend {
		static let infectionSummaryTitle = NSLocalizedString("BERiskLegend_infectionSummaryTitle", comment: "")
		static let infectionSummaryText = NSLocalizedString("BERiskLegend_infectionSummaryText", comment: "")
	}
	
	enum BEMobileTestIdActivator {
		static let linkTestToPhoneTitle = NSLocalizedString("BEMobileTestIdActivator_linkTestToPhoneTitle", comment: "")
		static let pageLoadErrorMessage = NSLocalizedString("BEMobileTestIdActivator_pageLoadError", comment: "")
		static let testActivatedTitle = NSLocalizedString("BEMobileTestIdActivator_testActivatedTitle", comment: "")
		static let testActivatedMessage = NSLocalizedString("BEMobileTestIdActivator_testActivatedMessage", comment: "")
	}
	
	enum BEAppResetAfterTEKUpload {
		static let title = NSLocalizedString("BEAppResetAfterTEKUpload_title", comment: "")
		static let description = NSLocalizedString("BEAppResetAfterTEKUpload_description", comment: "")
	}
	
	enum BESettings {
		static let mobileDataLabel = NSLocalizedString("BEMobileDataSettings_label", comment: "")
		static let mobileDataActive = NSLocalizedString("BEMobileDataSettings_active", comment: "")
		static let mobileDataInactive = NSLocalizedString("BEMobileDataSettings_inactive", comment: "")
		static let mobileDataDescription = NSLocalizedString("BEMobileDataSettings_description", comment: "")
	}
	
	enum BEMobileDataUsageSettings {
		static let description = NSLocalizedString("BEMobileDataUsageSettings_description", comment: "")
		static let navigationBarTitle = NSLocalizedString("BEMobileDataUsageSettings_navTitle", comment: "")
		static let title = NSLocalizedString("BEMobileDataUsageSettings_title", comment: "")
		static let toggleDescription = NSLocalizedString("BEMobileDataUsageSettings_toggleDescription", comment: "")
	}
}
