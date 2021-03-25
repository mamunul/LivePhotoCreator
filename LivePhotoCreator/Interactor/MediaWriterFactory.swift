//
//  MediaWriterFactory.swift
//  LivePhotoCreator
//
//  Created by New User on 25/3/21.
//

import AVFoundation
import Foundation

class MediaWriterFactory {
    func makeMetadatWriterInput() -> AVAssetWriterInput? {
        let spec = [
            [
                kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier: "mdta/com.apple.quicktime.still-image-time",
                kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType: kCMMetadataBaseDataType_SInt8 as String,
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

    func makeAudioWriterInput(with track: AVAssetTrack) -> AVAssetWriterInput {
        let input = AVAssetWriterInput(mediaType: track.mediaType, outputSettings: nil)
        return input
    }

    func makeAudioReaderOutput(with track: AVAssetTrack) -> AVAssetReaderTrackOutput {
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        return output
    }

    func makeVideoWriterInput(with track: AVAssetTrack) -> AVAssetWriterInput {
        var writerOuputSettings: [String: Any]?
        writerOuputSettings =
            [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: track.naturalSize.width,
                AVVideoHeightKey: track.naturalSize.height,
            ]

        let input = AVAssetWriterInput(mediaType: track.mediaType, outputSettings: writerOuputSettings)
        return input
    }

    func makeVideoReaderOutput(with track: AVAssetTrack) -> AVAssetReaderTrackOutput {
        var readerOutputSettings: [String: Any]?
        readerOutputSettings =
            [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]

        let output = AVAssetReaderTrackOutput(track: track, outputSettings: readerOutputSettings)
        return output
    }
}
