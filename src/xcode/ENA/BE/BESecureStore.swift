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

extension SecureStore {
	var mobileTestId: BEMobileTestId? {
		get { kvStore["mobileTestId"] as BEMobileTestId?}
		set { kvStore["mobileTestId"] = newValue }
	}
	
	var testResult:TestResult? {
		get { kvStore["testResult"] as TestResult?}
		set { kvStore["testResult"] = newValue }
	}
	
	var deleteMobileTestIdAfterTimeInterval: TimeInterval {
		get { kvStore["testIdDeleteTimeInterval"] as TimeInterval? ?? 14*60*60*24 }
		set { kvStore["testIdDeleteTimeInterval"] = newValue }
	}
	
	var lastBackgroundFakeRequest: Date {
		get { kvStore["lastBackgroundFakeRequest"] as Date? ?? Date() }
		set { kvStore["lastBackgroundFakeRequest"] = newValue }
	}

	var isDoingFakeRequests: Bool {
		get { kvStore["isDoingFakeRequests"] as Bool? ?? false }
		set { kvStore["isDoingFakeRequests"] = newValue }
	}
	
	var fakeRequestAmountOfTestResultFetchesToDo: Int {
		get { kvStore["fakeRequestAmountOfTestResultFetchesToDo"] as Int? ?? 4 }
		set { kvStore["fakeRequestAmountOfTestResultFetchesToDo"] = newValue }
	}

	var fakeRequestTestResultFetchIndex: Int {
		get { kvStore["fakeRequestAmountOfTestResultFetchesToDo"] as Int? ?? 0 }
		set { kvStore["fakeRequestAmountOfTestResultFetchesToDo"] = newValue }
	}

	var isAllowedToPerformBackgroundFakeRequests: Bool {
		get { kvStore["shouldPerformBackgroundFakeRequests"] as Bool? ?? false }
		set { kvStore["shouldPerformBackgroundFakeRequests"] = newValue }
	}

}
