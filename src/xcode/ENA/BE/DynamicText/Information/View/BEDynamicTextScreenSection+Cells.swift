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

/// What a mess, but changing the app into a fully generic dynamic text system on all screens would take a very long time

extension BEDynamicTextScreenSection {
	func buildRiskLevelDynamicCell() -> DynamicCell {
		if var paragraphs = self.paragraphs {
			if let text = self.text {
				paragraphs.insert(text, at: 0)
			}
			return DynamicCell.guide(image: self.icon, text: paragraphs)
		}

		if let text = self.text {
			return DynamicCell.guide(text: text, image: self.icon)
		}
		

		return DynamicCell.guide(image: self.icon, text: [])
	}
}

extension BEDynamicTextScreenSection {
	func buildSuccessViewControllerStepCells(iconTint:UIColor? = nil) -> [DynamicCell] {
		if let text = self.text,
			let icon = self.icon {
			return [
				ExposureSubmissionDynamicCell.stepCell(
				   style:.body,
				   title: text,
				   icon: icon,
				   iconTint: iconTint,
				   hairline: .none,
				   bottomSpacing: .normal
			   )
			]
		}
		
		if let paragraphs = self.paragraphs {
			return paragraphs.map{
				ExposureSubmissionDynamicCell.stepCell(
					bulletPoint: $0,
					hairline: .topAttached
				)
			}
		}

		fatalError("Should never happen")
	}
}

extension BEDynamicTextScreenSection {
	func buildTestResultStepCells(iconTint:UIColor? = nil) -> [DynamicCell] {
		guard
			let title = self.title else {
				if let paragraphs = self.paragraphs {
					/// Only paragraphs, make a bullet point list
					return paragraphs.map{ ExposureSubmissionDynamicCell.stepCell(bulletPoint: $0)}
				} else {
					fatalError("Should not happen")
				}
		}
		
		let firstCell = ExposureSubmissionDynamicCell.stepCell(
			title: title,
			description: self.text,
			icon: self.icon,
			iconTint: iconTint,
			hairline: .topAttached
		)
		
		var result = [firstCell]
		
		if let paragraphs = self.paragraphs {
			result.append(contentsOf: paragraphs.map{
				ExposureSubmissionDynamicCell.stepCell(
					bulletPoint: $0,
					hairline: .topAttached
				)
			})
		}
		
		return result
	}
}
