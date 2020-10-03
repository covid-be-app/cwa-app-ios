//
// Corona-Warn-App
//
// Modified by Devside SRL
//
// SAP SE and all other contributors
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

struct Risk: Codable {
	let level: RiskLevel
	let details: Details
	let riskLevelHasChanged: Bool
}

extension Risk {
	struct Details: Codable {
		var daysSinceLastExposure: Int?
		var numberOfExposures: Int?
		var numberOfHoursWithActiveTracing: Int { activeTracing.inHours }
		var activeTracing: ActiveTracing
		var numberOfDaysWithActiveTracing: Int { activeTracing.inDays }
		var exposureDetectionDate: Date?

		// :BE: get the correct number of days, taking into account when exposure was last calculated
		var calendarDaysSinceLastExposure: Int? {
			if  var daysSinceLastExposure = daysSinceLastExposure,
				let date = exposureDetectionDate {
				let calendar = Calendar.current
				let exposureDetectionDate = calendar.startOfDay(for: date)
				let today = calendar.startOfDay(for: Date())
				let components = calendar.dateComponents([.day], from: exposureDetectionDate, to: today)
				
				if let days = components.day {
					daysSinceLastExposure += days
				}

				return daysSinceLastExposure
			}
			
			return nil
		}
	}
}

#if UITESTING
extension Risk {
	static let mockedLow = Risk(
		level: .low,
		details: Risk.Details(
			numberOfExposures: 0,
			activeTracing: .init(interval: 336 * 3600),  // two weeks
			exposureDetectionDate: Date()),
		riskLevelHasChanged: true
	)
	static let mockedIncreased = Risk(
		level: .increased,
		details: Risk.Details(
			numberOfExposures: 1,
			activeTracing: .init(interval: 336 * 3600),  // two weeks
			exposureDetectionDate: Date()),
		riskLevelHasChanged: true
	)
}
#endif
