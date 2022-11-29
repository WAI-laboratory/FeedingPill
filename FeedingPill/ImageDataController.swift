//
//  DataController.swift
//  Edison
//
//  Created by 이용준 on 2021/03/13.
//

import UIKit
import RealmSwift
import Kingfisher

final class ImageDataController {
    static let shared = ImageDataController()
    
    let realm: Realm = DBService.shared.realm

    // MARK: - Save Image
    func save(alarm: RepeatableAlarm, image: UIImage, for imageID: String) {
        cache(image: image, for: imageID)
        let thumbnail = createThumbnail(from: image)
        cache(image: thumbnail, for: imageID + "_thumbnail")
    }
  
    func createThumbnail(from image: UIImage) -> UIImage {
        let image = image.resized(to: CGSize(width: 100, height: 100))
        return image
    }
    
    func cache(image: UIImage, for imageID: String) {
        ImageCache.default.store(image, forKey: imageID)
    }
    
    func getImage(alarm: RepeatableAlarm, handler: @escaping (UIImage?) -> Void) {
        guard let imageId = alarm.imageId else { return }
        ImageCache.default.retrieveImage(forKey: imageId)
        { [weak self] (result) in
            switch result {
            case let .success(result):
                switch result {
                case let .disk(image), let .memory(image):
                    handler(image)
                case .none:
                    Log.error("\(#file) \(#function) \(#line)", "none")
                }
            case let .failure(error):
                Log.error("\(#file) \(#function) \(#line)", error)
            }
        }
    }
    
    
    func getThumbnailImage(alarm: RepeatableAlarm, handler: @escaping (UIImage?) -> Void) {
        guard let imageId = alarm.imageId else { return }
        let thumbnailImageID = imageId + "_thumbnail"
        ImageCache.default.retrieveImage(forKey: thumbnailImageID) {[weak self] (result) in
            switch result {
            case let .success(result):
                switch result {
                case let .disk(image), let .memory(image):
                    handler(image)
                case .none:
                    Log.error("\(#file) \(#function) \(#line)", "none")
                }
            case let .failure(error):
                Log.error("\(#file) \(#function) \(#line)", error)
            }
        }
    }
    
    // MARK: - Delete Data
    private func deleteAll() {
        ImageCache.default.clearCache()
    }
    
    func deleteImage(alarm: RepeatableAlarm, for imageID: String) {
        ImageCache.default.removeImage(forKey: imageID)
        let thumbnailImageID = imageID + "_thumbnail"
        ImageCache.default.removeImage(forKey: thumbnailImageID)
    }
}


extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

