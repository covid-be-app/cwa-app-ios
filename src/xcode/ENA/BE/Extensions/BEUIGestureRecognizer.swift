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
import UIKit

extension UIGestureRecognizer {
	typealias Action = ((UIGestureRecognizer) -> ())

	private struct Keys {
		static var actionKey = "ActionKey"
	}

	private var block: Action? {
		set {
			if let newValue = newValue {
				// Computed properties get stored as associated objects
				objc_setAssociatedObject(self, &Keys.actionKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
			}
		}

		get {
			let action = objc_getAssociatedObject(self, &Keys.actionKey) as? Action
			return action
		}
	}

	@objc func handleAction(recognizer: UIGestureRecognizer) {
		block?(recognizer)
	}

	convenience public init(block: @escaping ((UIGestureRecognizer) -> ())) {
		self.init()
		self.block = block
		self.addTarget(self, action: #selector(handleAction(recognizer:)))
	}
}
