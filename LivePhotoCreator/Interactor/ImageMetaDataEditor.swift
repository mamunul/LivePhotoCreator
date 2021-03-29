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
    private let kFigAppleMakerNote_AssetIdentifier = "17"
    func addMetadataTo(imageURL: URL, assetIdentifier: String, outputURL: URL) -> Bool {
        let image = UIImage(contentsOfFile: imageURL.path)
        let imageRef = image?.cgImage
        let imageMetadata = [kCGImagePropertyMakerAppleDictionary: [kFigAppleMakerNote_AssetIdentifier: assetIdentifier]]

        let cfUrl = outputURL as CFURL

        let dest = CGImageDestinationCreateWithURL(cfUrl, kUTTypeJPEG, 1, nil)
        CGImageDestinationAddImage(dest!, imageRef!, imageMetadata as CFDictionary)
        let status = CGImageDestinationFinalize(dest!)
        return status
    }
    
    func addMetadataTo(image: UIImage, assetIdentifier: String, outputURL: URL) -> Bool {
        let imageRef = image.cgImage
        let imageMetadata = [kCGImagePropertyMakerAppleDictionary: [kFigAppleMakerNote_AssetIdentifier: assetIdentifier]]
        
        let cfUrl = outputURL as CFURL
        
        let dest = CGImageDestinationCreateWithURL(cfUrl, kUTTypeJPEG, 1, nil)
        CGImageDestinationAddImage(dest!, imageRef!, imageMetadata as CFDictionary)
        let status = CGImageDestinationFinalize(dest!)
        return status
    }
}
