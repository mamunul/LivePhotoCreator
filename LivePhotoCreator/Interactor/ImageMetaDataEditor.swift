//
//  ImageMetaDataEditor.swift
//  LivePhotoCreator
//
//  Created by New User on 25/3/21.
//

import CoreGraphics
import Foundation
import MobileCoreServices
import UIKit

class ImageMetaDataEditor {
    func addMetadataToPhoto(photoURL: URL, assetIdentifier: String, outputURL: URL) -> Bool {
        let image = UIImage(contentsOfFile: photoURL.path)
        let imageRef = image?.cgImage
        let imageMetadata = [kCGImagePropertyMakerAppleDictionary: ["17": assetIdentifier]]

        let cfUrl = outputURL as CFURL

        let dest = CGImageDestinationCreateWithURL(cfUrl, kUTTypeJPEG, 1, nil)
        CGImageDestinationAddImage(dest!, imageRef!, imageMetadata as CFDictionary)
        let status = CGImageDestinationFinalize(dest!)
        return status
    }
}
