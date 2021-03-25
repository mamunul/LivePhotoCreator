//
//  FileHandler.swift
//  WebClip
//
//  Created by Mamunul Mazid on 3/10/21.
//

import Foundation

class FileHandler {
    var filePath: URL?
    var videoFilePath: URL?

    init() {
        filePath = getDocumentsDirectory().appendingPathComponent("image.jpg")
        videoFilePath = getDocumentsDirectory().appendingPathComponent("video.mov")

        removeFile(at: filePath!)
        removeFile(at: videoFilePath!)
    }

    private func removeFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
