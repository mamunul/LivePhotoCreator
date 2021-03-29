//
//  WriterBuilder.swift
//  LivePhotoCreator
//
//  Created by New User on 29/3/21.
//

import AVFoundation
import Foundation

class WriterBuilder {
    private let videoMetadataFactory = VideoMetaDataFactory()
    private let writerFactory = MediaWriterFactory()

    func build(videoURL: URL, outputURL: URL, identifier: String) -> MediaReWriter? {
        let asset = AVAsset(url: videoURL)
        let adaptor = makeAdaptor()
        let timedMetadata = videoMetadataFactory.makeStillImageTimeMetaData()
        let metadataGroup = makeTimedMetadata(timedMetadata)
        guard let mediaReWriter = makeReWriter(asset, outputURL) else { return nil }

        mediaReWriter.adaptor = adaptor
        mediaReWriter.metadataGroup = metadataGroup

        addMetadata(asset, mediaReWriter, identifier)
        setupReadingWritingForAllTrack(asset.tracks, mediaReWriter)
        mediaReWriter.addWriterInput(adaptor.assetWriterInput)

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

    private func addMetadata(_ asset: AVAsset, _ mediaReWriter: MediaReWriter, _ identifier: String) {
        var metadata: [AVMetadataItem] = asset.metadata
        let item = videoMetadataFactory.makeIdentifierMetadata(assetIdentifier: identifier)
        metadata.append(item)
        mediaReWriter.addMetadata(metadata)
    }

    private func makeReWriter(_ asset: AVAsset, _ outputURL: URL) -> MediaReWriter? {
        var assetreader: AVAssetReader?
        var assetwriter: AVAssetWriter?

        do {
            assetreader = try AVAssetReader(asset: asset)
            assetwriter = try AVAssetWriter(url: outputURL, fileType: AVFileType.mov)
        } catch {
            print(error)
        }

        guard assetreader != nil, assetwriter != nil else { return nil }
        let mediaReWriter = MediaReWriter(assetReader: assetreader!, assetWriter: assetwriter!)
        return mediaReWriter
    }

    fileprivate func setupReadingWritingForAllTrack(_ assetTracks: [AVAssetTrack], _ mediaReWriter: MediaReWriter) {
        for track in assetTracks {
            if track.mediaType == .video {
                let output = writerFactory.makeVideoReaderOutput(with: track)
                let input = writerFactory.makeVideoWriterInput(with: track)
                mediaReWriter.addWriterInput(input)
                mediaReWriter.addReaderOutput(output)
            } else {
                let output = writerFactory.makeAudioReaderOutput(with: track)
                let input = writerFactory.makeAudioWriterInput(with: track)
                mediaReWriter.addWriterInput(input)
                mediaReWriter.addReaderOutput(output)
            }
        }
    }
}
