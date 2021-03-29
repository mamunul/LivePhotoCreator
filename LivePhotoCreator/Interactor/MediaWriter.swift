//
//  MediaWriter.swift
//  LivePhotoCreator
//
//  Created by New User on 25/3/21.
//

import AVFoundation
import Foundation

class WriterBuilder {
    private let videoMetadataFactory = VideoMetaDataFactory()
    private let writerFactory = MediaWriterFactory()

    func build(videoURL: URL, outputURL: URL, identifier: String) -> MediaWriter? {
        let asset = AVAsset(url: videoURL)
        let adaptor = makeAdaptor()
        let timedItem = videoMetadataFactory.makeStillImageTimeMetaData()
        let timedMetadata = makeTimedMetadata(timedItem)
        guard let mediaReWriter = makeReWriter(asset, outputURL, adaptor, timedMetadata) else { return nil }

        addMetadata(asset, mediaReWriter, identifier)
        setupReadingWritingForAllTrack(asset.tracks, mediaReWriter)
        addWriterInput(adaptor.assetWriterInput, to: mediaReWriter.assetwriter)

        return mediaReWriter
    }

    private func makeTimedMetadata(_ timedItem: AVMutableMetadataItem) -> AVTimedMetadataGroup {
        let timedRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMake(value: 1, timescale: 100))
        let timedMetadataGroup = AVTimedMetadataGroup(items: [timedItem], timeRange: timedRange)
        return timedMetadataGroup
    }

    private func makeAdaptor() -> AVAssetWriterInputMetadataAdaptor {
        let input = writerFactory.makeMetadatWriterInput()
        let adaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: input!)
        return adaptor
    }

    private func addMetadata(_ asset: AVAsset, _ mediaReWriter: MediaWriter, _ identifier: String) {
        var metadata: [AVMetadataItem] = asset.metadata
        let item = videoMetadataFactory.makeIdentifierMetadata(assetIdentifier: identifier)
        metadata.append(item)
        mediaReWriter.assetwriter.metadata = metadata
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

    private func makeReWriter(
        _ asset: AVAsset,
        _ outputURL: URL,
        _ adaptor: AVAssetWriterInputMetadataAdaptor,
        _ timedMetadata: AVTimedMetadataGroup
    ) -> MediaWriter? {
        var assetreader: AVAssetReader?
        var assetwriter: AVAssetWriter?

        do {
            assetreader = try AVAssetReader(asset: asset)
            assetwriter = try AVAssetWriter(url: outputURL, fileType: AVFileType.mov)
        } catch {
            print(error)
        }

        guard assetreader != nil, assetwriter != nil else { return nil }
        let mediaReWriter =
            MediaWriter(
                assetreader: assetreader!,
                assetwriter: assetwriter!,
                adaptor: adaptor,
                timedMetadataGroup: timedMetadata
            )
        return mediaReWriter
    }

    fileprivate func setupReadingWritingForAllTrack(_ assetTracks: [AVAssetTrack], _ mediaReWriter: MediaWriter) {
        for track in assetTracks {
            if track.mediaType == .video {
                let output = writerFactory.makeVideoReaderOutput(with: track)
                let input = writerFactory.makeVideoWriterInput(with: track)
                addWriterInput(input, to: mediaReWriter.assetwriter)
                addReaderOutput(output, to: mediaReWriter.assetreader)
            } else {
                let output = writerFactory.makeAudioReaderOutput(with: track)
                let input = writerFactory.makeAudioWriterInput(with: track)
                addWriterInput(input, to: mediaReWriter.assetwriter)
                addReaderOutput(output, to: mediaReWriter.assetreader)
            }
        }
    }
}

class MediaWriter {
    private(set) var assetreader: AVAssetReader
    private(set) var assetwriter: AVAssetWriter
    private var adaptor: AVAssetWriterInputMetadataAdaptor
    private var timedMetadataGroup: AVTimedMetadataGroup
    private var queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
    private var group = DispatchGroup()

    init(
        assetreader: AVAssetReader,
        assetwriter: AVAssetWriter,
        adaptor: AVAssetWriterInputMetadataAdaptor,
        timedMetadataGroup: AVTimedMetadataGroup
    ) {
        self.assetreader = assetreader
        self.assetwriter = assetwriter
        self.adaptor = adaptor
        self.timedMetadataGroup = timedMetadataGroup
    }

    func start(onCompletion: @escaping () -> Void) {
        assetreader.startReading()
        assetwriter.startWriting()
        assetwriter.startSession(atSourceTime: CMTime.zero)

        adaptor.append(timedMetadataGroup)

        for i in 0 ..< assetreader.outputs.count {
            group.enter()
            writeTrack(output: assetreader.outputs[i], input: assetwriter.inputs[i], reader: assetreader)
        }

        group.notify(queue: queue) { [self] in
            assetreader.cancelReading()
            assetwriter.finishWriting {
                onCompletion()
            }
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
