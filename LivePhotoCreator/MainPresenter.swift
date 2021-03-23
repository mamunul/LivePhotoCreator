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

    private var filePath: URL?

    func generateLivePhoto(onCompletion: @escaping (PHLivePhoto?) -> Void) {
        VideoConnverter().fetchPhotoFromLibrary { photo in
//        VideoConnverter().convertToLive { photo in
            onCompletion(photo)
        }
    }
}
