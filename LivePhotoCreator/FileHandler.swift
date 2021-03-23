//
//  FileHandler.swift
//  WebClip
//
//  Created by Mamunul Mazid on 3/10/21.
//

import Foundation

class FileHandler {
    var filePath: URL?

    init() {
        filePath = getDocumentsDirectory()
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
