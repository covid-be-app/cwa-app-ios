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
import CoreImage

extension UIImage {
	
	static func generateQRCode(_ contents:String,size:CGFloat) -> UIImage {
		let context = CIContext()
		let filter = CIFilter(name: "CIQRCodeGenerator")!
		filter.setDefaults()
		filter.setValue(contents.data(using: .utf8), forKey: "inputMessage")
		
		let extent = filter.outputImage!.extent
		let scale =  size / extent.width
		let outputImage = filter.outputImage!.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
		
		let cgImage = context.createCGImage(outputImage, from: CGRect(origin: .zero, size: CGSize(width: outputImage.extent.width, height: outputImage.extent.height)))!
		
		return UIImage(cgImage: cgImage)
	}
}
