import UIKit

extension UIImage {
    func rotated(by degrees: Double) -> UIImage {
      let radians = CGFloat(degrees * .pi / 180.0)
      UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

      guard
        let bitmap = UIGraphicsGetCurrentContext(),
        let cgImage = cgImage
        else { return self }

      bitmap.translateBy(x: size.width / 2, y: size.height / 2)
      bitmap.rotate(by: radians)
      bitmap.scaleBy(x: 1.0, y: -1.0)

      let rect = CGRect(
        x: -size.width / 2,
        y: -size.height / 2,
        width: size.width,
        height: size.height)
      bitmap.draw(cgImage, in: rect)

      return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
