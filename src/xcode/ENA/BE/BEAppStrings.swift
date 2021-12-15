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
		
		static let subtitle = NSLocalizedString("BEMobileTestId_subtitle", comment: "")

		static let close = NSLocalizedString("BEMobileTestId_Close", comment: "")
		static let saveExplanation = NSLocalizedString("BEMobileTestId_saveExplanation", comment: "")
		static let saveExplanation2 = NSLocalizedString("BEMobileTestId_saveExplanation2", comment: "")

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
	
	enum BEExposureNotificationSettings {
		static let euTracingRiskDeterminationTitle = NSLocalizedString("ExposureNotificationSetting_euTracingRiskDeterminationTitle", comment: "")
		static let euTracingAllCountriesTitle = NSLocalizedString("ExposureNotificationSetting_euTracingAllCountriesTitle", comment: "")

		static let euTitle = NSLocalizedString("ExposureNotificationSetting_EU_Title", comment: "")
		static let euDescription1 = NSLocalizedString("ExposureNotificationSetting_EU_Desc_1", comment: "")
		static let euDescription2 = NSLocalizedString("ExposureNotificationSetting_EU_Desc_2", comment: "")
		static let euDescription3 = NSLocalizedString("ExposureNotificationSetting_EU_Desc_3", comment: "")
		static let euDescription4 = NSLocalizedString("ExposureNotificationSetting_EU_Desc_4", comment: "")
	}
	
	enum BEAppDisabled {
		static let text = NSLocalizedString("App_Disabled_Text", comment: "")
	}
	
	enum BEHome {
		static let toolboxTitle = NSLocalizedString("BEHome_Toolbox_title", comment: "")
		static let toolboxDescription = NSLocalizedString("BEHome_Toolbox_description", comment: "")

		static let coviCodeTitle = NSLocalizedString("BEHome_CoviCode_title", comment: "")
		static let coviCodeDescription = NSLocalizedString("BEHome_CoviCode_description", comment: "")
		static let coviCodeButton = NSLocalizedString("BEHome_CoviCode_button", comment: "")

		static let riskCardHighButton = NSLocalizedString("BEHome_riskCardHigh_button", comment: "")
		static let requestTestURL = URL(string: NSLocalizedString("BEHome_requestTestURL", comment: ""))!
	}
	
	enum BECoviCode {
		static let title = NSLocalizedString("BECoviCode_title", comment: "")
		static let subtitle = NSLocalizedString("BECoviCode_subtitle", comment: "")
		static let button = NSLocalizedString("BECoviCode_button", comment: "")
		static let explanation = NSLocalizedString("BECoviCode_explanation", comment: "")
		static let submit = NSLocalizedString("BECoviCode_submit", comment: "")
		static let enterCodeTitle = NSLocalizedString("BECoviCode_enterCodeTitle", comment: "")
		static let enterCodeDescription = NSLocalizedString("BECoviCode_enterCodeDescription", comment: "")
		static let ok = NSLocalizedString("BECoviCode_ok", comment: "")
		static let cancel = NSLocalizedString("BECoviCode_cancel", comment: "")
	}
	
	enum BEToolbox {
		static let vaccinationInformation = NSLocalizedString("BEHome_BEToolbox_vaccinationInformation", comment: "")
		static let testCenter = NSLocalizedString("BEHome_BEToolbox_testCenter", comment: "")
		static let testReservation = NSLocalizedString("BEHome_BEToolbox_testReservation", comment: "")
		static let quarantineCertificate = NSLocalizedString("BEHome_BEToolbox_quarantineCertificate", comment: "")
		static let passengerLocatorForm = NSLocalizedString("BEHome_BEToolbox_passengerLocatorForm", comment: "")
		static let declarationOfHonour = NSLocalizedString("BEHome_BEToolbox_declarationOfHonour", comment: "")

		static let vaccinationInformationTitle = NSLocalizedString("BEHome_BEToolbox_vaccinationInformationTitle", comment: "")
		static let testReservationTitle = NSLocalizedString("BEHome_BEToolbox_testReservationTitle", comment: "")
		static let quarantineCertificateTitle = NSLocalizedString("BEHome_BEToolbox_quarantineCertificateTitle", comment: "")
		static let passengerLocatorFormTitle = NSLocalizedString("BEHome_BEToolbox_passengerLocatorFormTitle", comment: "")

		
		static let epidemiologicalSituation = NSLocalizedString("BEHome_BEToolbox_epidemiologicalSituation", comment: "")
		static let registerToBeVaccinated = NSLocalizedString("BEHome_BEToolbox_registerToBeVaccinated", comment: "")
		
		static let epidemiologicalSituationURL = URL(string: "https://datastudio.google.com/embed/u/0/reporting/c14a5cfc-cab7-4812-848c-0369173148ab/page/hOMwB")!
		static let registerToBeVaccinatedURL = URL(string: "https://www.qvax.be/region")!
		
		
		static let bookATest = NSLocalizedString("BEHome_BEToolbox_bookATest", comment: "")
		static let bookATestURL = URL(string: "https://testcovid.doclr.be")!
		
		static let bookATestInBrussels = NSLocalizedString("BEHome_BEToolbox_bookATestInBrussels", comment: "")
		static let bookATestInBrusselsURL = URL(string: "https://brussels.testcovid.be/fr")!

		static let quarantineCertificateURL = URL(string: NSLocalizedString("BEHome_BEToolbox_quarantineCertificateURL", comment: ""))!

		static let passengerLocatorFormFR = "Formulaire de Localisation du Passager"
		static let passengerLocatorFormEN = "Passenger Locator Form"
		static let passengerLocatorFormNL = "Passenger Locator Form"
		static let passengerLocatorFormDE = "Passagier-Lokalisierungsformular"

		static let passengerLocatorFormURLFR = URL(string: "https://travel.info-coronavirus.be/fr/public-health-passenger-locator-form")!
		static let passengerLocatorFormURLEN = URL(string: "https://travel.info-coronavirus.be/public-health-passenger-locator-form")!
		static let passengerLocatorFormURLNL = URL(string: "https://travel.info-coronavirus.be/nl/public-health-passenger-locator-form")!
		static let passengerLocatorFormURLDE = URL(string: "https://travel.info-coronavirus.be/de/public-health-passenger-locator-form")!

		static let testCenterURL = URL(string: "https://testcovid.doclr.be/#!/saps")!
	}
	
	enum BEAlreadyDidTest {
		static let title = NSLocalizedString("BEAlreadyDidTest_title", comment: "")
		
		static let possibilitiesTitle = NSLocalizedString("BEAlreadyDidTest_possibilitiesTitle", comment: "")
		static let possibility1 = NSLocalizedString("BEAlreadyDidTest_possibility1", comment: "")
		static let possibility2 = NSLocalizedString("BEAlreadyDidTest_possibility2", comment: "")
		static let possibility3 = NSLocalizedString("BEAlreadyDidTest_possibility3", comment: "")
		
		static let close = NSLocalizedString("BEMobileTestId_Close", comment: "")
		static let imageDescription = NSLocalizedString("BEAlreadyDidTest_AccImageDescription", comment: "")
	}
	
	enum BEExposureSubmissionError {
		static let invalidCoviCode = NSLocalizedString("BEExposureSubmissionError_invalidCoviCode", comment: "")
	}
	
	enum BEVaccinationInfo {
		static let title = NSLocalizedString("BEVaccinationInfo_title", comment: "")
		static let atLeastOneDose = NSLocalizedString("BEVaccinationInfo_atLeastOneDose", comment: "")
		static let fullyVaccinated = NSLocalizedString("BEVaccinationInfo_fullyVaccinated", comment: "")
		static let updatedAt = NSLocalizedString("BEVaccinationInfo_updatedAt", comment: "")
	}
	
	enum BECovidSafe {
		static let homeTitle = NSLocalizedString("BECovidSafe_cardTitle", comment: "")
		static let title = NSLocalizedString("BECovidSafe_title", comment: "")
		static let appTitle = NSLocalizedString("BECovidSafe_appTitle", comment: "")
		static let appSubtitle = NSLocalizedString("BECovidSafe_appSubtitle", comment: "")
		static let appButton = NSLocalizedString("BECovidSafe_appButton", comment: "")
	}
}
