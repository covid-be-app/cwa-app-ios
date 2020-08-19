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


class BEFakeRequestsExecutor {
	
	private let store:Store
	private let exposureManager:ExposureManager
	private let client:Client

	// we want to run a fake request approx every 5 days, and the function deciding it is called every 2 hours
	// so we want a 1 in 12 * 5 = a 1 in 60 chance of this happening
	private var fakeRequestProbability:UInt32 = 60
	

	private var isTest:Bool = false
	
	init(store:Store,exposureManager:ExposureManager,client:Client, isTest:Bool = false) {
		self.store = store
		self.exposureManager = exposureManager
		self.client = client
		self.isTest = isTest
		
		// no randomness when running in test mode
		if isTest {
			fakeRequestProbability = 1
		}
	}
	
	func execute(_ completion: @escaping (() -> Void)) {
		log(message:"Fake requests")
		
		if store.isAllowedToPerformBackgroundFakeRequests == false {
			log(message:"Not yet allowed to do fake requests")
			completion()
			return
		}
		
		// we don't run the fake request flow if we are currently waiting for a test result
		if store.registrationToken != nil {
			log(message:"Has token, no fake requests")
			store.isDoingFakeRequests = false
			completion()
			return
		}
		
		// or if we have a test result
		if let testResult = store.testResult {
			if testResult.result != .pending {
				log(message:"Has test results, no fake requests")
				store.isDoingFakeRequests = false
				completion()
				return
			}
		}
		
		if store.isDoingFakeRequests {
			continueCurrentFakeRequests(completion)
			return
		}
		
		log(message:"See if we want to do a fake request")
		let randomValue = arc4random_uniform(fakeRequestProbability)
		
		// number doesn't really matter here as long as we stick to the same
		// but we use fakeRequestProbability - 1 so in test code we always compare 0 to 0
		if randomValue == fakeRequestProbability - 1 {
			log(message:"We want to do a fake request")
			store.isDoingFakeRequests = true
			
			// we execute a random amount of fetch test results
			
			// in test mode this is already filled out
			if !isTest {
				store.fakeRequestAmountOfTestResultFetchesToDo = Int(2 + arc4random_uniform(5))
			}
			
			log(message:"We want to do \(store.fakeRequestAmountOfTestResultFetchesToDo) fake fetch test requests")
			store.fakeRequestTestResultFetchIndex = 0
			
			// actual fake calls will start next time executeFakeRequests is called
		}

		completion()
	}
	
	
	private func continueCurrentFakeRequests(_ completion: @escaping (() -> Void)) {
		log(message:"Continue current fake request")
		let service = BEExposureSubmissionServiceImpl(diagnosiskeyRetrieval: exposureManager, client: client, store: store)

		if store.fakeRequestTestResultFetchIndex < store.fakeRequestAmountOfTestResultFetchesToDo {
			doFakeFetchTestResult(service:service,completion:completion)
			return
		}
		
		completion()
	}
	
	private func doFakeFetchTestResult(service:BEExposureSubmissionService ,completion: @escaping (() -> Void)) {
		log(message:"Get fake test result")
		store.fakeRequestTestResultFetchIndex += 1
		let isLast = self.store.fakeRequestTestResultFetchIndex == self.store.fakeRequestAmountOfTestResultFetchesToDo
		
		service.getFakeTestResult(isLast) { 
			log(message:"Get fake test result done")
			if isLast {
				self.doFakeKeyUpload(service:service, completion:completion)
				return
			}
			
			completion()
		}
	}
	
	private func doFakeKeyUpload(service:BEExposureSubmissionService ,completion: @escaping (() -> Void)) {
		log(message:"Do fake key upload")
		
		// introduce a random delay between 5 and 15 seconds
		let delay = Double(5 + Int(arc4random_uniform(10)))
		
		DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
			service.submitFakeExposure { _ in
				log(message:"Fake key upload done")

				// end of the fake request chain
				self.store.isDoingFakeRequests = false
				completion()
			}
		}
	}
}
