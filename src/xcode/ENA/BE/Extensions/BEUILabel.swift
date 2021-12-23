//  Created by Alexandre Oliveira Santos on 2/3/20.
//  Copyright © 2020 iAOS. All rights reserved.
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// Modified by Devside SRL
//

import UIKit

public extension UILabel {
    // MARK: - Custom Flags
    private struct AssociatedKeys {
        static var isCopyingEnabled: UInt8 = 0
        static var shouldUseLongPressGestureRecognizer: UInt8 = 1
        static var longPressGestureRecognizer: UInt8 = 2
    }

    /// Set this property to `true` in order to enable the copy feature. Defaults to `false`.
    @objc var isCopyingEnabled: Bool {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isCopyingEnabled, newValue, .OBJC_ASSOCIATION_ASSIGN)
            setupGestureRecognizers()
        }
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKeys.isCopyingEnabled)
            return (value as? Bool) ?? false
        }
    }


    /// Used to enable/disable the internal long press gesture recognizer. Defaults to `true`.
    var shouldUseLongPressGestureRecognizer: Bool {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.shouldUseLongPressGestureRecognizer, newValue, .OBJC_ASSOCIATION_ASSIGN)
            setupGestureRecognizers()
        }
        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.shouldUseLongPressGestureRecognizer) as? Bool) ?? true
        }
    }

    @objc
    var longPressGestureRecognizer: UILongPressGestureRecognizer? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.longPressGestureRecognizer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.longPressGestureRecognizer) as? UILongPressGestureRecognizer
        }
    }
    
    // MARK: - UIResponder
    @objc
    override var canBecomeFirstResponder: Bool {
        return isCopyingEnabled
    }

    @objc
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // Only return `true` when it's the copy: action AND the `copyingEnabled` property is `true`.
        return (action == #selector(self.copy(_:)) && isCopyingEnabled)
    }

    @objc
    override func copy(_ sender: Any?) {
        if isCopyingEnabled {
            // Copy the label text
            let pasteboard = UIPasteboard.general
            pasteboard.string = text
        }
    }

    // MARK: - UI Actions
    @objc internal func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer === longPressGestureRecognizer && gestureRecognizer.state == .began {
            becomeFirstResponder()

            let copyMenu = UIMenuController.shared
            copyMenu.arrowDirection = .default
            if #available(iOS 13.0, *) {
                copyMenu.showMenu(from: self, rect: bounds)
            } else {
                // Fallback on earlier versions
                copyMenu.setTargetRect(bounds, in: self)
                copyMenu.setMenuVisible(true, animated: true)
            }
        }
    }

    // MARK: - Private Helpers
    fileprivate func setupGestureRecognizers() {
        // Remove gesture recognizer
        if let longPressGR = longPressGestureRecognizer {
            removeGestureRecognizer(longPressGR)
            longPressGestureRecognizer = nil
        }

        if shouldUseLongPressGestureRecognizer && isCopyingEnabled {
            isUserInteractionEnabled = true
            // Enable gesture recognizer
            let longPressGR = UILongPressGestureRecognizer(target: self,
                                                           action: #selector(longPressGestureRecognized(gestureRecognizer:)))
            longPressGestureRecognizer = longPressGR
            addGestureRecognizer(longPressGR)
        }
    }
}

extension UILabel {
	
	/// Checks the text for links / phone numbers, and adds a button the size of the label that will open the link or call the number
	/// This only works for 1 link or 1 phone number per label, mutually exclusive and the button will cover the entire label
	
	func addOpenActionForSupportedTypes() {
		var textRange: NSRange?
		
		textRange = addOpenActionForLink()
		
		if textRange == nil {
			textRange = addOpenActionForPhoneNumber()
		}

		if let range = textRange {
			let labelText = NSMutableAttributedString(attributedString: attributedText!)  // we know it's not nil
			labelText.addAttribute(.foregroundColor, value: UIColor.enaColor(for: .textTint), range: range)
			self.text = nil
			self.attributedText = labelText
		}
	}
	
	private func addOpenActionForLink() -> NSRange? {
		guard let text = text else {
		   return nil
		}

		if let firstUrlMatch = text.findFirstURL() {
			addAction(firstUrlMatch.url)
			return firstUrlMatch.range
		}

		return nil
	}
	
	private func addOpenActionForPhoneNumber() -> NSRange? {
		guard let text = text else {
		   return nil
		}

		if let firstMatch = text.findFirstPhoneNumber(),
		   let phoneUrl = URL(string:"telprompt://\(firstMatch.phoneNumber.replacingOccurrences(of: " ", with: ""))") {
			addAction(phoneUrl)
			return firstMatch.range
		}

		return nil
	}
	
	private func addAction(_ url: URL) {
		let recog = UITapGestureRecognizer { _ in
			if UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.open(url, options: [:], completionHandler:nil)
			}
		}
		
		addGestureRecognizer(recog)
		self.isUserInteractionEnabled = true
	}
}
