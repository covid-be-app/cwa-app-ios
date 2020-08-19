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

import Foundation

class BEMockURLSession: URLSession {
	typealias URLRequestObserver = ((URLRequest) -> Void)
	var datas: [Data?]
	var nextResponses: [URLResponse?]
	let onURLRequestObserver: URLRequestObserver?

	init(
		datas:[Data?],
		nextResponses: [URLResponse?],
		urlRequestObserver: URLRequestObserver? = nil
	) {
		self.datas = datas
		self.nextResponses = nextResponses
		self.onURLRequestObserver = urlRequestObserver
	}

	override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
		onURLRequestObserver?(URLRequest(url: url))
		let data = self.datas.remove(at: 0)
		let response = self.nextResponses.remove(at: 0)

		return MockURLSessionDataTask {
			completionHandler(data, response, nil)
		}
	}

	override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
		onURLRequestObserver?(request)

		print(request.url!.absoluteString)
		print("\(self.datas.count)")
		let data = self.datas.remove(at: 0)
		let response = self.nextResponses.remove(at: 0)

		return MockURLSessionDataTask {
			completionHandler(data, response, nil)
		}
	}
}
