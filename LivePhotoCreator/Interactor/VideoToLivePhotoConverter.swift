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
    private let fileHandler = FileHandler()
    private let imageMetadataEditor = ImageMetaDataEditor()

    private let builder = WriterBuilder()

    init() {
    }

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

    func convertVideoToLive(videoURL: URL, onCompletion: @escaping (PHLivePhoto?) -> Void) {
        guard let thumbnailImage = getThumbOfVideo(fileURL: videoURL) else { return }

        let identifier = UUID().uuidString

        fileHandler.removeExistingFiles()

        let mediaWriter = builder.build(videoURL: videoURL, outputURL: fileHandler.videoFileUrl!, identifier: identifier)

        _ = imageMetadataEditor.addMetadataTo(
            image: thumbnailImage,
            assetIdentifier: identifier,
            outputURL: fileHandler.imageFileUrl!
        )

        mediaWriter?.start { [self] in
            let urlList = [fileHandler.imageFileUrl!, fileHandler.videoFileUrl!]
            self.makeLivephoto(placeHolderImage: thumbnailImage, urlList, onCompletion: onCompletion)
        }
    }

    private func getThumbOfVideo(fileURL: URL) -> UIImage? {
        let movieAsset = AVURLAsset(url: fileURL)
        let assetImageGenerator = AVAssetImageGenerator(asset: movieAsset)
        assetImageGenerator.appliesPreferredTrackTransform = true

        var thumbnail: UIImage?
        do {
            let cgImage = try assetImageGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1000), actualTime: nil)
            thumbnail = UIImage(cgImage: cgImage)
        } catch {
            print(error)
        }

        return thumbnail
    }

    func convertToLive(onCompletion: @escaping (PHLivePhoto?) -> Void) {
        let imageName = "img2s"
        let placeHolderImage = UIImage(named: imageName)

        let imageURL = Bundle.main.url(forResource: imageName, withExtension: "jpg")!
        let videoURL = Bundle.main.url(forResource: imageName, withExtension: "mov")!
        let identifier = UUID().uuidString

        fileHandler.removeExistingFiles()

        let mediaWriter = builder.build(videoURL: videoURL, outputURL: fileHandler.videoFileUrl!, identifier: identifier)

        _ = imageMetadataEditor.addMetadataTo(
            imageURL: imageURL,
            assetIdentifier: identifier,
            outputURL: fileHandler.imageFileUrl!
        )
        mediaWriter?.start { [self] in
            let urlList = [fileHandler.imageFileUrl!, fileHandler.videoFileUrl!]
            self.makeLivephoto(placeHolderImage: placeHolderImage, urlList, onCompletion: onCompletion)
        }
    }

    func fetchLivePhotoFromLibrary(onCompletion: @escaping (PHLivePhoto?) -> Void) {
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
