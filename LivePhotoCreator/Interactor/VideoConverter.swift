//
//  VideoConverter.swift
//  WebClip
//
//  Created by New User on 23/3/21.
//

import Foundation
import Photos
import UIKit

class VideoToLivePhotoConverter {
    let fileHandler = FileHandler()

    let imageMetadataEditor = ImageMetaDataEditor()
    let mediaWriter = MediaWriter()

    private func makeLivephoto(placeHolderImage: UIImage?, _ urlList: [URL], onCompletion: @escaping (PHLivePhoto?) -> Void) {
        PHLivePhoto.request(
            withResourceFileURLs: urlList,
            placeholderImage: placeHolderImage,
            targetSize: CGSize(width: 200, height: 400),
            contentMode: PHImageContentMode.aspectFit
        ) { livephoto, _ in
            onCompletion(livephoto)
        }
    }

    func convertToLive(onCompletion: @escaping (PHLivePhoto?) -> Void) {
        let imageName = "img2s"
        let placeHolderImage = UIImage(named: imageName)

        let imageURL = Bundle.main.url(forResource: imageName, withExtension: "jpg")!
        let videoURL = Bundle.main.url(forResource: imageName, withExtension: "mov")!
        let identifier = UUID().uuidString

        _ = imageMetadataEditor.addMetadataToPhoto(photoURL: imageURL, assetIdentifier: identifier, outputURL: fileHandler.filePath!)
        mediaWriter.addMetadataToVideo(
            videoURL: videoURL,
            outputURL: fileHandler.videoFilePath!,
            identifier: identifier
        ) { newVideoURL in
            let urlList = [self.fileHandler.filePath!, newVideoURL]
            self.makeLivephoto(placeHolderImage: placeHolderImage, urlList, onCompletion: onCompletion)
        }
    }

    func fetchPhotoFromLibrary(onCompletion: @escaping (PHLivePhoto?) -> Void) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let liveImagesPredicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
        options.predicate = liveImagesPredicate

        let photos = PHAsset.fetchAssets(with: options)
        guard let asset = photos.firstObject else { return }
        PHImageManager.default().requestLivePhoto(
            for: asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: PHImageContentMode.aspectFit,
            options: nil
        ) { livePhoto, _ in
            onCompletion(livePhoto)
        }
    }
}
