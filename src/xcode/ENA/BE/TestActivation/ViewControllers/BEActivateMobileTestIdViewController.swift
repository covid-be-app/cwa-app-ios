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

import UIKit
import WebKit

protocol BEActivateMobileTestIdViewControllerDelegate: class {
	func activateMobileTestIdViewControllerFinished(_: BEActivateMobileTestIdViewController)
	func activateMobileTestIdViewControllerCancelled(_: BEActivateMobileTestIdViewController)
}

class BEActivateMobileTestIdViewController: UIViewController, SpinnerInjectable {
	
	/// When the webpage redirects to one of these, we know the form has been submitted correctly
	static let successRedirectPaths = [
		"coronalert-formulier-bevestiging",
		"formulaire-coronalert-confirmation",
		"coronalert-formular-bestatigung",
		"corona-alert-form-confirmation"
	]
	
	var spinner: UIActivityIndicatorView?

	@IBOutlet weak var webView:WKWebView!

	private let mobileTestId: BEMobileTestId
	private let url:URL
	private weak var delegate: BEActivateMobileTestIdViewControllerDelegate?
	
	init(mobileTestId: BEMobileTestId, url: URL, delegate: BEActivateMobileTestIdViewControllerDelegate) {
		self.mobileTestId = mobileTestId
		self.url = url
		self.delegate = delegate
		
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		webView.navigationDelegate = self
		loadWebPage()
    }
	
	func loadWebPage() {
		startSpinner()
		guard let targetUrl = URL(string: url.absoluteString + "&read-only=1") else {
			showError()
			return
		}
		
		let urlRequest = URLRequest(url: targetUrl)
		webView.load(urlRequest)
		webView.alpha = 0
	}
	
	fileprivate func showError() {
		stopSpinner()
		let alert = setupErrorAlert(title: nil, message: BEAppStrings.BEMobileTestIdActivator.pageLoadErrorMessage, okTitle: AppStrings.Common.alertActionRetry, secondaryActionTitle: AppStrings.Common.alertActionCancel, completion: {
			self.loadWebPage()
		}) {
			self.delegate?.activateMobileTestIdViewControllerCancelled(self)
		}
		
		self.present(alert, animated: true)
	}
	
	/// We remove a lot of html components to remove all the "mobile website" parts, such as the menu bar, unused components and part of the footer
	fileprivate func removeClutter() {
		let javascriptCleanupCode = """
		document.getElementsByClassName("navbar")[0].style.display = "none";
		document.getElementsByClassName("entry-header")[0].style.display = "none";
		document.getElementsByClassName("vc_row")[0].style.display = "none";
		document.getElementsByClassName("vc_row")[1].style.display = "none";
		document.getElementsByClassName("upper-footer")[0].style.display = "none";
		document.getElementById("wrapper").style.paddingTop = "0";
		"""
		
		webView.evaluateJavaScript(javascriptCleanupCode) { _, error in
			if let error = error {
				logError(message: error.localizedDescription)
				self.showError()
			}
			self.webView.alpha = 1
		}

	}

	/// Execute JS to fill out code and date fields
	fileprivate func fillFields() {
		guard let date = mobileTestId.datePatientInfectious.dateWithoutTime else {
			fatalError("Should never happen")
		}
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd/MM/yyyy"
		
		let codeToExecute = "setDate(\"\(dateFormatter.string(from: date))\");setCode(\"\(mobileTestId.fullString)\");"
		webView.evaluateJavaScript(codeToExecute) { _, error in
			if let error = error {
				logError(message: error.localizedDescription)
				self.showError()
			}
			self.webView.alpha = 1
		}
	}
}

extension BEActivateMobileTestIdViewController: WKNavigationDelegate {
	
	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		logError(message: "Navigation error \(error)")
		showError()
	}
	
	func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) {
		logError(message: "Navigation error \(withError)")
		showError()
	}
	
	func webView(_: WKWebView, didFinish: WKNavigation!) {
		log(message: "Page loaded")
		stopSpinner()
		removeClutter()
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			self.fillFields()
		}
	}
	
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		log(message: "\(navigationAction)")
		
		if let url = navigationAction.request.url {
			let urlString = url.absoluteString

			/// successful submission
			if Self.successRedirectPaths.first(where:{ urlString.contains($0)}) != nil {
				decisionHandler(.cancel)
				delegate?.activateMobileTestIdViewControllerFinished(self)
				return
			}
		}

		decisionHandler(.allow)
	}
}
