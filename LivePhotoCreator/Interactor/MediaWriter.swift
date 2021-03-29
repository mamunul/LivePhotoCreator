//
//  MediaWriter.swift
//  LivePhotoCreator
//
//  Created by New User on 25/3/21.
//

import AVFoundation
import Foundation

class MediaWriter {
    private var queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
    private var group = DispatchGroup()
    private let videoMetadataEditor = VideoMetaDataFactory()
    private let writerFactory = MediaWriterFactory()

    fileprivate func setupReadingWritingForAllTrack(_ assetTracks: [AVAssetTrack], _ writer: AVAssetWriter?, _ reader: AVAssetReader?) {
        for track in assetTracks {
            if track.mediaType == .video {
                let output = writerFactory.makeVideoReaderOutput(with: track)
                let input = writerFactory.makeVideoWriterInput(with: track)
                addWriterInput(input, to: writer!)
                addReaderOutput(output, to: reader!)
            } else {
                let output = writerFactory.makeAudioReaderOutput(with: track)
                let input = writerFactory.makeAudioWriterInput(with: track)
                addWriterInput(input, to: writer!)
                addReaderOutput(output, to: reader!)
            }
        }
    }

    func addMetadataToVideo(videoURL: URL, outputURL: URL, identifier: String, onCompletion: @escaping () -> Void) {
        let asset = AVAsset(url: videoURL)
        var assetreader: AVAssetReader?
        var assetwriter: AVAssetWriter?

        do {
            assetreader = try AVAssetReader(asset: asset)
            assetwriter = try AVAssetWriter(url: outputURL, fileType: AVFileType.mov)
        } catch {
            print(error)
        }

        guard let reader = assetreader, let writer = assetwriter else { return }

        var metadata: [AVMetadataItem] = asset.metadata
        let item = videoMetadataEditor.makeIdentifierMetadata(assetIdentifier: identifier)
        metadata.append(item)
        writer.metadata = metadata

        setupReadingWritingForAllTrack(asset.tracks, writer, reader)

        let input = writerFactory.makeMetadatWriterInput()
        let adaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: input!)
        if writer.canAdd(adaptor.assetWriterInput) {
            writer.add(adaptor.assetWriterInput)
        }

        reader.startReading()
        writer.startWriting()
        writer.startSession(atSourceTime: CMTime.zero)

        let timedItem = videoMetadataEditor.makeStillImageTimeMetaData()
        let timedRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMake(value: 1, timescale: 100))
        let timedMetadataGroup = AVTimedMetadataGroup(items: [timedItem], timeRange: timedRange)
        adaptor.append(timedMetadataGroup)
        
        for i in 0 ..< reader.outputs.count {
            group.enter()
            writeTrack(output: reader.outputs[i], input: writer.inputs[i], reader: reader)
        }

        group.notify(queue: queue) {
            reader.cancelReading()
            writer.finishWriting {
                onCompletion()
            }
        }
    }

    private func addReaderOutput(_ output: AVAssetReaderTrackOutput, to reader: AVAssetReader) {
        if reader.canAdd(output) {
            reader.add(output)
        }
    }

    private func addWriterInput(_ input: AVAssetWriterInput, to writer: AVAssetWriter) {
        if writer.canAdd(input) {
            writer.add(input)
        }
    }

    func writeTrack(output: AVAssetReaderOutput, input: AVAssetWriterInput, reader: AVAssetReader) {
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
