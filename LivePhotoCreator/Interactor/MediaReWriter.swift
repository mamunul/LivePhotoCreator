//
//  MediaWriter.swift
//  LivePhotoCreator
//
//  Created by New User on 25/3/21.
//

import AVFoundation
import Foundation

class MediaReWriter {
    private var assetReader: AVAssetReader
    private var assetWriter: AVAssetWriter
    var adaptor: AVAssetWriterInputMetadataAdaptor?
    var metadataGroup: AVTimedMetadataGroup?
    private var queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
    private var group = DispatchGroup()

    init(assetReader: AVAssetReader, assetWriter: AVAssetWriter) {
        self.assetReader = assetReader
        self.assetWriter = assetWriter
    }

    func start(onCompletion: @escaping () -> Void) {
        assetReader.startReading()
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMTime.zero)

        adaptor?.append(metadataGroup!)

        for i in 0 ..< assetReader.outputs.count {
            group.enter()
            writeTrack(output: assetReader.outputs[i], input: assetWriter.inputs[i], reader: assetReader)
        }

        group.notify(queue: queue) { [self] in
            assetReader.cancelReading()
            assetWriter.finishWriting {
                onCompletion()
            }
        }
    }

    func addMetadata(_ metadata: [AVMetadataItem]) {
        assetWriter.metadata = metadata
    }

    func addReaderOutput(_ output: AVAssetReaderTrackOutput) {
        if assetReader.canAdd(output) {
            assetReader.add(output)
        }
    }

    func addWriterInput(_ input: AVAssetWriterInput) {
        if assetWriter.canAdd(input) {
            assetWriter.add(input)
        }
    }

    private func writeTrack(output: AVAssetReaderOutput, input: AVAssetWriterInput, reader: AVAssetReader) {
        input.requestMediaDataWhenReady(on: queue) {
            while input.isReadyForMoreMediaData {
                if reader.status != .reading {
                    input.markAsFinished()
                    self.group.leave()
                    break
                }
                guard let buffer = output.copyNextSampleBuffer() else { continue }
                if !input.append(buffer) {
                    input.markAsFinished()
                    self.group.leave()
                    break
                }
            }
        }
    }
}
