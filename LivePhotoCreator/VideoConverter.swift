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
    let fileHandler = FileHandler()

    let kFigAppleMakerNote_AssetIdentifier = "17"
    var session: AVAssetExportSession?
    var asset: AVURLAsset?
    var reader: AVAssetReader?
    var writer: AVAssetWriter?
    var queue = DispatchQueue(label: "test")
    var group = DispatchGroup()

    func convertToLive(onCompletion: @escaping (PHLivePhoto?) -> Void) {
//        let imageName = "IMG_0810"
        let imageName = "img2s"
        let placeHolderImage = UIImage(named: imageName)

        let imageURL = Bundle.main.url(forResource: imageName, withExtension: "jpg")!
        let videoURL = Bundle.main.url(forResource: imageName, withExtension: "mov")!
        let identifier = UUID().uuidString

        addMetadataToPhoto(photoURL: imageURL, assetIdentifier: identifier) { photoURL in
            self.addMetadataToVideo(videoURL: videoURL, outputURL: self.fileHandler.videoFilePath!, identifier: identifier) { newVideoURL in
                let urlList = [photoURL, newVideoURL]

                PHLivePhoto.request(withResourceFileURLs: urlList, placeholderImage: placeHolderImage, targetSize: CGSize(width: 200, height: 400), contentMode: PHImageContentMode.aspectFit) { livephoto, _ in
                    onCompletion(livephoto)
                }
            }
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

    func createIdentifierMetadata(assetIdentifier: String) -> AVMutableMetadataItem {
        let metadata = AVMutableMetadataItem()
        metadata.keySpace = AVMetadataKeySpace.quickTimeMetadata
        metadata.key = AVMetadataKey.quickTimeMetadataKeyContentIdentifier as NSString
        metadata.identifier = AVMetadataIdentifier.quickTimeMetadataContentIdentifier

        metadata.value = assetIdentifier as NSString

        return metadata
    }

    func addStillImageTimeMetaDataToVideoFile(uuid: String) -> AVMutableMetadataItem {
        let metadata2 = AVMutableMetadataItem()
        metadata2.keySpace = AVMetadataKeySpace.quickTimeMetadata
        metadata2.key = "com.apple.quicktime.still-image-time" as NSString

        metadata2.value = 0 as (NSCopying & NSObjectProtocol)?
        metadata2.dataType = kCMMetadataBaseDataType_SInt8 as String

        return metadata2
    }

    func createStillImageTimeAssetWriterInput() -> AVAssetWriterInput? {
        let spec = [
            [
                kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String: "mdta/com.apple.quicktime.still-image-time",
                kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String: kCMMetadataBaseDataType_SInt8 as String,
            ],
        ]
        var desc: CMFormatDescription?

        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
            allocator: kCFAllocatorDefault,
            metadataType: kCMMetadataFormatType_Boxed,
            metadataSpecifications: spec as CFArray,
            formatDescriptionOut: &desc
        )

        let input = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil, sourceFormatHint: desc)
        return input
    }

    func addMetadataToVideo(videoURL: URL, outputURL: URL, identifier: String, onCompletion: @escaping (URL) -> Void) {
        let asset = AVAsset(url: videoURL)
        let reader = try? AVAssetReader(asset: asset)

        var metadata: [AVMetadataItem] = asset.metadata
        let item = createIdentifierMetadata(assetIdentifier: identifier)
        metadata.append(item)

        let writer = try? AVAssetWriter(url: outputURL, fileType: AVFileType.mov)
        writer?.metadata = metadata

        let tracks: [AVAssetTrack] = asset.tracks
        for track in tracks {
            var readerOutputSettings: [String: Any]?
            var writerOuputSettings: [String: Any]?
            if track.mediaType == .audio {
//                readerOutputSettings = [AVFormatIDKey: kAudioFormatLinearPCM]
//                writerOuputSettings =
//                    [
//                        AVFormatIDKey: kAudioFormatMPEG4AAC,
//                        AVSampleRateKey: 44100,
//                        AVNumberOfChannelsKey: 2,
//                        AVEncoderBitRateKey: 128000,
//                    ]
            } else if track.mediaType == .video {
                readerOutputSettings = [kCVPixelBufferPixelFormatTypeKey as String:
                    NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]

                writerOuputSettings = [
                    AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
                    AVVideoWidthKey: track.naturalSize.width as AnyObject,
                    AVVideoHeightKey: track.naturalSize.height as AnyObject,
                ]
            }
            let output = AVAssetReaderTrackOutput(track: track, outputSettings: readerOutputSettings)
            let input = AVAssetWriterInput(mediaType: track.mediaType, outputSettings: writerOuputSettings)
            if (reader?.canAdd(output))! && writer!.canAdd(input) {
                reader?.add(output)
                writer?.add(input)
            }
        }

        let input2 = createStillImageTimeAssetWriterInput()
        let adaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: input2!)
        if writer!.canAdd(adaptor.assetWriterInput) {
            writer!.add(adaptor.assetWriterInput)
        }

        reader?.startReading()
        writer?.startWriting()
        writer?.startSession(atSourceTime: CMTime.zero)

        let timedItem = addStillImageTimeMetaDataToVideoFile(uuid: identifier)
        let timedRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMake(value: 1, timescale: 100))
        let timedMetadataGroup = AVTimedMetadataGroup(items: [timedItem], timeRange: timedRange)
        adaptor.append(timedMetadataGroup)
//
        self.reader = reader
        self.writer = writer
        queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        group = DispatchGroup()
        for i in 0 ..< reader!.outputs.count {
            group.enter()
            writeTrack(trackIndex: i)
        }

        group.notify(queue: queue) {
            self.reader!.cancelReading()
            self.writer?.finishWriting {
                onCompletion(outputURL)
            }
        }
    }

    func writeTrack(trackIndex: Int) {
        let output = reader!.outputs[trackIndex]
        let input = writer!.inputs[trackIndex]

        input.requestMediaDataWhenReady(on: queue) {
            while input.isReadyForMoreMediaData {
                let status = self.reader!.status
                if status == .reading {
                    if let buffer = output.copyNextSampleBuffer() {
                        print("ready:\(input.isReadyForMoreMediaData)")
                        let status = input.append(buffer)
                        NSLog("Track %d. Failed to append buffer.", trackIndex)
                        if !status {
                            print("leave track:\(trackIndex)")
                            input.markAsFinished()
                            self.group.leave()
                            return
                        }
                    }
                } else {
                    print("leave track:\(trackIndex)")
                    input.markAsFinished()
                    self.group.leave()
                    return
                }
            }
        }
    }

    func addMetadataToPhoto(photoURL: URL, assetIdentifier: String, onCompletion: @escaping (URL) -> Void) {
        let image = UIImage(contentsOfFile: photoURL.path)
        let imageRef = image?.cgImage
        let imageMetadata = [kCGImagePropertyMakerAppleDictionary: ["17": assetIdentifier]]

        let cfurl = fileHandler.filePath! as CFURL

        let dest = CGImageDestinationCreateWithURL(cfurl, kUTTypeJPEG, 1, nil)
        CGImageDestinationAddImage(dest!, imageRef!, imageMetadata as CFDictionary)
        CGImageDestinationFinalize(dest!)

        DispatchQueue.global().async {
            onCompletion(self.fileHandler.filePath!)
        }
    }
}
