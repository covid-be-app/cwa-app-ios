//
// Corona-Warn-App
//
// SAP SE and all other contributors
//
// Modified by Devside SRL
//
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

// :BE: replace ENAExposureSubmissionService with BEExposureSubmissionService

/// Service factory that can be used to create an instance of the ExposureSubmissionService.
class ExposureSubmissionServiceFactory { }

// MARK: Default implementation.
#if !UITESTING

extension ExposureSubmissionServiceFactory {
	static func create(diagnosiskeyRetrieval: DiagnosisKeysRetrieval, client: Client, store: Store) -> ExposureSubmissionService {
		return BEExposureSubmissionServiceImpl(
			diagnosiskeyRetrieval: diagnosiskeyRetrieval,
			client: client,
			store: store
		)
	}
}

#endif

// MARK: UI Testing implementation.
#if UITESTING

/// This extension will return a mock service if and only if the .useMock parameter is passed to the application.
/// If the parameter is _not_ provided, the factory will instantiate a regular BEExposureSubmissionService.
/// - NOTE: This is condtionally compiled so no test code spills into the release build.
extension ExposureSubmissionServiceFactory {
	static func create(diagnosiskeyRetrieval: DiagnosisKeysRetrieval, client: Client, store: Store) -> ExposureSubmissionService {

		guard isEnabled(.useMock) else {
			return BEExposureSubmissionServiceImpl(
				diagnosiskeyRetrieval: diagnosiskeyRetrieval,
				client: client,
				store: store
			)
		}

		// :BE: mock BE service
		let service = BEMockExposureSubmissionService()

		// :BE: registration token fetching does not exist on our side

		return service
	}

	private static func isEnabled(_ parameter: UITestingParameters.ExposureSubmission) -> Bool {
		return ProcessInfo.processInfo.arguments.contains(parameter.rawValue)
	}
}

#endif
