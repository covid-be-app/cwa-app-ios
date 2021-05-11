//
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
//

import Foundation
import UIKit

class ENANavigationControllerWithFooter: UINavigationController {
	private var navigationItemObserver: ENANavigationFooterItem.Observer?

	private(set) var footerView: ENANavigationFooterView! { didSet { footerView.delegate = self } }

	private var keyboardWillShowObserver: NSObjectProtocol?
	private var keyboardWillHideObserver: NSObjectProtocol?
	private var keyboardWillChangeFrameObserver: NSObjectProtocol?
	private var keyboardWindowFrame: CGRect?
	private var isKeyboardHidden: Bool = true

	private(set) var isFooterViewHidden: Bool = true

	private var topViewControllerWithFooterChild: ENANavigationControllerWithFooterChild? { topViewController as? ENANavigationControllerWithFooterChild }

	var doKeyboardObservation: Bool = true
	
	override func loadView() {
		super.loadView()

		footerView = ENANavigationFooterView(effect: UIBlurEffect(style: .regular))
		view.addSubview(footerView)

		if let topViewController = topViewController {
			updateFooterView(for: topViewController)
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if doKeyboardObservation {
			observeKeyboard()
		}
		
		observeNavigationItem(of: topViewController)
		footerView.apply(navigationItem: topViewController?.navigationItem)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if doKeyboardObservation {
			removeKeyboardObserver()
		}
		
		navigationItemObserver?.invalidate()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		updateAdditionalSafeAreaInsets()
		layoutFooterView()
	}
}

private extension ENANavigationControllerWithFooter {
	func observeKeyboard() {
		keyboardWillShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in
			guard let self = self else { return }
			self.isKeyboardHidden = false
			self.keyboardWindowFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue

			guard nil == self.transitionCoordinator else { return }
			self.updateAdditionalSafeAreaInsets()
			self.layoutFooterView()
		}

		keyboardWillHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] notification in
			guard let self = self else { return }
			self.isKeyboardHidden = true
			self.keyboardWindowFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue

			guard nil == self.transitionCoordinator else { return }
			self.updateAdditionalSafeAreaInsets()
			self.layoutFooterView()
		}

		keyboardWillChangeFrameObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: nil) { [weak self] notification in
			guard let self = self else { return }
			self.keyboardWindowFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue

			guard nil == self.transitionCoordinator else { return }
			self.updateAdditionalSafeAreaInsets()
			self.layoutFooterView()
		}
	}

	func removeKeyboardObserver() {
		NotificationCenter.default.removeObserver(keyboardWillShowObserver as Any, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(keyboardWillHideObserver as Any, name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.removeObserver(keyboardWillChangeFrameObserver as Any, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
	}
}

extension ENANavigationControllerWithFooter {
	private func updateAdditionalSafeAreaInsets() {
		let baseInset = view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom
		var bottomInset: CGFloat = 0

		if !isFooterViewHidden {
			let footerViewSize = footerView.sizeThatFits(view.bounds.size)
			bottomInset += footerViewSize.height
		}

		if !isKeyboardHidden {
			if let keyboardWindowFrame = keyboardWindowFrame {
				let localOrigin = view.convert(keyboardWindowFrame, from: nil)
				let keyboardInset = view.bounds.height - localOrigin.minY
				if keyboardInset > baseInset { bottomInset += keyboardInset - baseInset }
			}
		}

		additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)

		if nil != view.window && nil == transitionCoordinator {
			topViewController?.view.layoutIfNeeded()
		}
	}
}

extension ENANavigationControllerWithFooter {
	override func pushViewController(_ viewController: UIViewController, animated: Bool) {
		super.pushViewController(viewController, animated: animated)
		transitionFooterView(to: viewController)
	}

	override func popViewController(animated: Bool) -> UIViewController? {
		let viewController = super.popViewController(animated: animated)
		transitionFooterView(to: topViewController)
		return viewController
	}

	override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
		super.setViewControllers(viewControllers, animated: animated)
		transitionFooterView(to: topViewController)
	}
}

extension ENANavigationControllerWithFooter {
	func setFooterViewHidden(_ isHidden: Bool, animated: Bool) {
		if animated {
			UIView.animate(withDuration: CATransaction.animationDuration()) {
				self.setFooterViewHidden(isHidden)
				self.updateAdditionalSafeAreaInsets()
				self.layoutFooterView()
			}
		} else {
			self.setFooterViewHidden(isHidden)
			self.updateAdditionalSafeAreaInsets()
			self.layoutFooterView()
		}
	}

	private func setFooterViewHidden(_ isHidden: Bool) {
		guard isHidden != isFooterViewHidden else { return }
		isFooterViewHidden = isHidden
	}

	private func layoutFooterView() {
		var frame = CGRect(
			x: 0,
			y: view.bounds.height,
			width: view.bounds.width,
			height: view.safeAreaInsets.bottom
		)

		if isFooterViewHidden {
			frame.size.height = 0
			footerView.bottomInset = 0
		} else {
			frame.origin.y -= view.safeAreaInsets.bottom
			footerView.bottomInset = view.safeAreaInsets.bottom
		}

		footerView.bounds.size = frame.size
		footerView.setNeedsLayout()
		footerView.layoutIfNeeded()
		footerView.frame.origin = frame.origin
	}

	private func updateFooterView(for viewController: UIViewController) {
		navigationItemObserver?.invalidate()

		self.footerView.apply(navigationItem: viewController.hidesBottomBarWhenPushed ? nil : viewController.navigationItem)
		self.setFooterViewHidden(viewController.hidesBottomBarWhenPushed)
		self.updateAdditionalSafeAreaInsets()
		self.layoutFooterView()

		observeNavigationItem(of: viewController)
	}

	private func transitionFooterView(to viewController: UIViewController?) {
		if nil != firstResponder {
			log(message: "[\(String(describing: Self.self))] Keyboard must be dismissed in `viewWillDisappear` of child before transitioning to another view controller!", level: .warning)
		}

		transitionCoordinator?.animate(alongsideTransition: { context in
			if let toViewController = context.viewController(forKey: .to) {
				self.updateFooterView(for: toViewController)
			}
		}, completion: { context in
			if context.isCancelled, let fromViewController = context.viewController(forKey: .from) {
				self.updateFooterView(for: fromViewController)
			}
		})

		if nil == transitionCoordinator, let viewController = viewController {
			self.updateFooterView(for: viewController)
		}
	}
}

extension ENANavigationControllerWithFooter {
	private func observeNavigationItem(of viewController: UIViewController?) {
		guard let viewController = viewController else { return }
		navigationItemObserver = (viewController.navigationItem as? ENANavigationFooterItem)?.observe(observer: navigationItemObserver)
	}

	private func navigationItemObserver(_ navigationItem: UINavigationItem) {
		if nil != view.window && nil == transitionCoordinator {
			UIView.animate(withDuration: CATransaction.animationDuration()) {
				self.footerView.apply(navigationItem: self.isFooterViewHidden ? nil : navigationItem)
				self.updateAdditionalSafeAreaInsets()
				self.layoutFooterView()
			}
		} else {
			self.footerView.apply(navigationItem: self.isFooterViewHidden ? nil : navigationItem)
			self.updateAdditionalSafeAreaInsets()
			self.layoutFooterView()
		}
	}
}

extension ENANavigationControllerWithFooter: ENAButtonFooterViewDelegate {
	func footerView(_ footerView: UIView, didTapPrimaryButton button: UIButton) {
		guard nil == transitionCoordinator else { return }
		topViewControllerWithFooterChild?.navigationController(self, didTapPrimaryButton: button)

	}

	func footerView(_ footerView: UIView, didTapSecondaryButton button: UIButton) {
		guard nil == transitionCoordinator else { return }
		topViewControllerWithFooterChild?.navigationController(self, didTapSecondaryButton: button)
	}
}

private extension ENANavigationFooterItem {
	struct Observer {
		fileprivate var observers: [NSKeyValueObservation]

		mutating func invalidate() {
			observers.forEach({ $0.invalidate() })
			observers = []
		}
	}

	func observe(observer: @escaping (UINavigationItem) -> Void) -> Observer {
		let observers = [
			observe(\.isPrimaryButtonHidden, changeHandler: { _, _ in observer(self) }),
			observe(\.isPrimaryButtonEnabled, changeHandler: { _, _ in observer(self) }),
			observe(\.isPrimaryButtonLoading, changeHandler: { _, _ in observer(self) }),
			observe(\.primaryButtonTitle, changeHandler: { _, _ in observer(self) }),
			observe(\.isSecondaryButtonHidden, changeHandler: { _, _ in observer(self) }),
			observe(\.isSecondaryButtonEnabled, changeHandler: { _, _ in observer(self) }),
			observe(\.isSecondaryButtonLoading, changeHandler: { _, _ in observer(self) }),
			observe(\.secondaryButtonTitle, changeHandler: { _, _ in observer(self) })
		]
		return Observer(observers: observers)
	}
}

private extension UIViewController {
	var firstResponder: UIResponder? { view.firstResponder }
}

private extension UIView {
	var firstResponder: UIResponder? {
		if self.isFirstResponder { return self }
		for subview in subviews {
			let firstResponder = subview.firstResponder
			if nil != firstResponder { return firstResponder }
		}
		return nil
	}
}
