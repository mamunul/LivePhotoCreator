//
//  VideoMetaDataEditor.swift
//  LivePhotoCreator
//
//  Created by New User on 25/3/21.
//

import AVFoundation
import Foundation

class VideoMetaDataFactory {
    func makeIdentifierMetadata(assetIdentifier: String) -> AVMutableMetadataItem {
        let metadata = AVMutableMetadataItem()
        metadata.keySpace = AVMetadataKeySpace.quickTimeMetadata
        metadata.key = AVMetadataKey.quickTimeMetadataKeyContentIdentifier as NSString
        metadata.identifier = AVMetadataIdentifier.quickTimeMetadataContentIdentifier
        metadata.value = assetIdentifier as NSString

        return metadata
    }

    func makeStillImageTimeMetaData() -> AVMutableMetadataItem {
        let metadata = AVMutableMetadataItem()
        metadata.keySpace = AVMetadataKeySpace.quickTimeMetadata
        metadata.key = "com.apple.quicktime.still-image-time" as NSString
        metadata.value = 0 as (NSCopying & NSObjectProtocol)?
        metadata.dataType = kCMMetadataBaseDataType_SInt8 as String

        return metadata
    }
}
