//
//  MainPresenter.swift
//  WebClip
//
//  Created by Mamunul Mazid on 3/10/21.
//

import Foundation
import Photos

class MainPresenter {
    let fileHandler = FileHandler()
    let videoConverter = VideoToLivePhotoConverter()

    private var filePath: URL?

    func generateLivePhoto(onCompletion: @escaping (PHLivePhoto?) -> Void) {
        let imageName = "img2s"
        let videoURL = Bundle.main.url(forResource: imageName, withExtension: "mov")!
        videoConverter.convertVideoToLive(videoURL: videoURL) { photo in
            if photo != nil {
                onCompletion(photo!)
            }
        }
    }

    func showLivePhotoFromLibrary(onCompletion: @escaping (PHLivePhoto?) -> Void) {
        videoConverter.fetchLivePhotoFromLibrary { photo in
            if photo != nil {
                onCompletion(photo!)
            }
        }
    }
}
