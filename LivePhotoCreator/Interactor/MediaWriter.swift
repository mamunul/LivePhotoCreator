//
//  MediaWriter.swift
//  LivePhotoCreator
//
//  Created by New User on 25/3/21.
//

import AVFoundation
import Foundation

class MediaWriter {
    let kFigAppleMakerNote_AssetIdentifier = "17"
    var session: AVAssetExportSession?
    var asset: AVURLAsset?
    var reader: AVAssetReader?
    var writer: AVAssetWriter?
    var queue = DispatchQueue(label: "test")
    var group = DispatchGroup()
    let videoMetadataEditor = VideoMetaDataEditor()
    let writerFactory = MediaWriterFactory()

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

    func addMetadataToVideo(videoURL: URL, outputURL: URL, identifier: String, onCompletion: @escaping (URL) -> Void) {
        let asset = AVAsset(url: videoURL)
        let reader = try? AVAssetReader(asset: asset)
        let writer = try? AVAssetWriter(url: outputURL, fileType: AVFileType.mov)

        var metadata: [AVMetadataItem] = asset.metadata
        let item = videoMetadataEditor.makeIdentifierMetadata(assetIdentifier: identifier)
        metadata.append(item)
        writer?.metadata = metadata

        setupReadingWritingForAllTrack(asset.tracks, writer, reader)

        let input2 = writerFactory.makeMetadatWriterInput()
        let adaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: input2!)
        if writer!.canAdd(adaptor.assetWriterInput) {
            writer!.add(adaptor.assetWriterInput)
        }

        reader?.startReading()
        writer?.startWriting()
        writer?.startSession(atSourceTime: CMTime.zero)

        let timedItem = videoMetadataEditor.makeStillImageTimeMetaData()
        let timedRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMake(value: 1, timescale: 100))
        let timedMetadataGroup = AVTimedMetadataGroup(items: [timedItem], timeRange: timedRange)
        adaptor.append(timedMetadataGroup)
        //
        self.reader = reader
        self.writer = writer
        queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        group = DispatchGroup()
        for i in 0 ..< reader!.outputs.count {
            group.enter()
            writeTrack(trackIndex: i)
        }

        group.notify(queue: queue) {
            self.reader!.cancelReading()
            self.writer?.finishWriting {
                onCompletion(outputURL)
            }
        }
    }

    func addReaderOutput(_ output: AVAssetReaderTrackOutput, to reader: AVAssetReader) {
        if reader.canAdd(output) {
            reader.add(output)
        }
    }

    func addWriterInput(_ input: AVAssetWriterInput, to writer: AVAssetWriter) {
        if writer.canAdd(input) {
            writer.add(input)
        }
    }

    func writeTrack(trackIndex: Int) {
        let output = reader!.outputs[trackIndex]
        let input = writer!.inputs[trackIndex]

        input.requestMediaDataWhenReady(on: queue) {
            while input.isReadyForMoreMediaData {
                if self.reader!.status != .reading {
                    input.markAsFinished()
                    self.group.leave()
                    break
                }
                guard let buffer = output.copyNextSampleBuffer() else { return }
                if !input.append(buffer) {
                    input.markAsFinished()
                    self.group.leave()
                    break
                }
            }
        }
    }
}
