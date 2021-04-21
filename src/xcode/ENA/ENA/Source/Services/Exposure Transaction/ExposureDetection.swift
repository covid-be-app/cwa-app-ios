// Corona-Warn-App
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

import ExposureNotification
import Foundation
import OpenCombine

/// Every time the user wants to know the own risk the app creates an `ExposureDetection`.
final class ExposureDetection {
	// MARK: Properties
	private weak var delegate: ExposureDetectionDelegate?
	private var configuration: ENExposureConfiguration
	private var completion: Completion?

	// MARK: Creating a Transaction
	init(
		configuration: ENExposureConfiguration,
		delegate: ExposureDetectionDelegate
	) {
		self.configuration = configuration
		self.delegate = delegate
	}

	// MARK: Starting the Transaction
	// Called right after the transaction knows which data is available remotly.
	private func downloadDeltaUsingAvailableRemoteData(_ remote: DaysAndHours?, region: BERegion) -> Future<Void, Error> {
		
		let future = Future<Void, Error> { promise in
			log(message: "Download delta for \(region.rawValue)")
			
			guard let remote = remote else {
				log(message: "No days and hours")
				promise(.success(()))
				return
			}
			guard let delta = self.delegate?.exposureDetection(self, downloadDeltaFor: remote, region: region) else {
				log(message: "No days and hours 2")
				promise(.success(()))
				return
			}

			log(message: "delta \(delta)")

			self.delegate?.exposureDetection(self, downloadAndStore: delta, region: region) { error in
				if error != nil {
					promise(.success(()))
					return
				}
				
				promise(.success(()))
			}
		}

		return future
	}
	
	
	private func downloadPackagesForRegions( regions: ArraySlice<BERegion>) -> AnyPublisher<Void, Error> {
		var remaining = regions
		if let region = remaining.popFirst() {
			guard let delegate = delegate else {
				return Future<Void, Error> { promise in
					promise(.success(()))
				}.eraseToAnyPublisher()
			}
			
			log(message: "Download package for \(region.rawValue)")
			return delegate.exposureDetectionDetermineAvailableData(self, region: region)
				.flatMap { daysAndHours in
					self.downloadDeltaUsingAvailableRemoteData(daysAndHours, region: region)
				}.flatMap { _ in
					self.downloadPackagesForRegions(regions: remaining)
				}.eraseToAnyPublisher()
		} else {
			return Future<Void, Error> { promise in
				promise(.success(()))
			}.eraseToAnyPublisher()
		}
	}

	private func useConfiguration() {
		var urls: [URL] = []
		do {
			try FileManager.default.removeTemporaryDirectoryContents()
		} catch {
			log(message: "Failed to clean temp folder \(error.localizedDescription)", level: .error)
		}
		
		BERegion.allCases.forEach { region in
			guard let writtenPackages = delegate?.exposureDetectionWriteDownloadedPackages(self, region: region) else {
				endPrematurely(reason: .unableToWriteDiagnosisKeys)
				return
			}
			
			urls += writtenPackages.urls
		}
		log(message: "url count \(urls.count)")
		log(message: "urls \(urls)")
		
		let writtenPackages = WrittenPackages(urls: urls)
		
		delegate?.exposureDetection(
			self,
			detectSummaryWithConfiguration: configuration,
			writtenPackages: writtenPackages
		) { [weak self] result in
			writtenPackages.cleanUp()
			self?.useSummaryResult(result)
		}
	}

	private func useSummaryResult(_ result: Result<ENExposureDetectionSummary, Error>) {
		switch result {
		case .success(let summary):
			didDetectSummary(summary)
		case .failure(let error):
			endPrematurely(reason: .noSummary(error))
		}
	}

	private var exposureSubscription: AnyCancellable?
	
	typealias Completion = (Result<ENExposureDetectionSummary, DidEndPrematurelyReason>) -> Void
	func start(completionBlock: @escaping Completion) {
		self.completion = completionBlock
		
		exposureSubscription = downloadPackagesForRegions(regions: ArraySlice(BERegion.allCases))
			.sink(receiveCompletion: { completion in
				switch completion {
				case .finished:
					break
				case .failure(let error):
					if let reason = error as? DidEndPrematurelyReason {
						completionBlock(.failure(reason))
					} else {
						completionBlock(.failure(.generic))
					}
				}
		}, receiveValue: { _ in
			self.useConfiguration()
		})
	}

	// MARK: Working with the Completion Handler

	// Ends the transaction prematurely with a given reason.
	private func endPrematurely(reason: DidEndPrematurelyReason) {
		precondition(
			completion != nil,
			"Tried to end a detection prematurely is only possible if a detection is currently running."
		)
		DispatchQueue.main.async {
			self.completion?(.failure(reason))
			self.completion = nil
		}
	}

	// Informs the delegate about a summary.
	private func didDetectSummary(_ summary: ENExposureDetectionSummary) {
		precondition(
			completion != nil,
			"Tried report a summary but no completion handler is set."
		)
		DispatchQueue.main.async {
			self.completion?(.success(summary))
			self.completion = nil
		}

	}
}
