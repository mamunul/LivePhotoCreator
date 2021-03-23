//
//  VideoConverter.swift
//  WebClip
//
//  Created by New User on 23/3/21.
//

import AVFoundation
import CoreGraphics
import Foundation
import MobileCoreServices
import Photos
import UIKit

class VideoConnverter {
    func convertToLive(onCompletion: @escaping (PHLivePhoto?) -> Void) {
        let imageName = "IMG_0810"
//        let imageName = "img2s"
        let placeHolderImage = UIImage(named: imageName)

        let imageURL = Bundle.main.url(forResource: imageName, withExtension: "jpg")!
        let videoURL = Bundle.main.url(forResource: imageName, withExtension: "mov")!

        let urlList = [imageURL, videoURL]

        PHLivePhoto.request(withResourceFileURLs: urlList, placeholderImage: placeHolderImage, targetSize: CGSize(width: 200, height: 200), contentMode: PHImageContentMode.aspectFit) { livephoto, _ in
            onCompletion(livephoto)
        }
    }

    func fetchPhotoFromLibrary(onCompletion: @escaping (PHLivePhoto?) -> Void) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let liveImagesPredicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
        options.predicate = liveImagesPredicate

        let photos = PHAsset.fetchAssets(with: options)
        if let asset = photos.firstObject {
            PHImageManager.default().requestLivePhoto(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: PHImageContentMode.aspectFit, options: nil) { livePhoto, _ in
                onCompletion(livePhoto)
            }
        }
    }

    func addMetaDataToVideoFile(uuid: String) {
        let metadata = AVMutableMetadataItem()
        metadata.keySpace = AVMetadataKeySpace.quickTimeMetadata
        metadata.key = AVMetadataKey.quickTimeMetadataKeyContentIdentifier as NSString
        metadata.identifier = AVMetadataIdentifier.quickTimeMetadataContentIdentifier

        metadata.value = uuid as NSString
//        metadata.value = String(format: "%+09.5f%+010.5f%+.0fCRSWGS_84", location.c
        
        let metadata2 = AVMutableMetadataItem()
        metadata2.keySpace = AVMetadataKeySpace.quickTimeMetadata
        metadata2.key = "com.apple.quicktime.still-image-time" as NSString
      
        metadata2.value = 0 as (NSCopying & NSObjectProtocol)?
//        metadata2.dataType = "com.apple.metadata.datatype.int8"
//        metadata2.value = 0
    }
    
    func addMetaDataToImageFile(uuid: String){
        let yourImage = UIImage()
        let imageData = yourImage.jpegData(compressionQuality: 0.5)
        let source = CGImageSourceCreateWithData( imageData! as CFData, nil)

        let newData = CFDataCreateMutable(kCFAllocatorDefault, 0)!
        
        let imageDest = CGImageDestinationCreateWithData(newData, kUTTypeJPEG, 1, nil)
        CGImageDestinationAddImageFromSource(imageDest!, source!, 0, nil)
        CGImageDestinationFinalize(imageDest!)
    }
}
