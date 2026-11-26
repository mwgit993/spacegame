// encode.swift: PNG frame sequence + WAV -> H.264/AAC MP4 using AVFoundation (macOS only).
// Usage: swift encode.swift <frames_dir> <prefix> <fps> <audio.wav> <out.mp4> [width height]
// Frames are drawn with nearest-neighbour scaling if they aren't already width x height.
import AVFoundation
import CoreGraphics
import Foundation
import ImageIO

let a = CommandLine.arguments
guard a.count >= 6 else {
    FileHandle.standardError.write("usage: encode.swift <frames_dir> <prefix> <fps> <audio.wav> <out.mp4> [w h]\n".data(using: .utf8)!)
    exit(2)
}
let dir = URL(fileURLWithPath: a[1])
let prefix = a[2]
let fps = Int32(a[3])!
let audioURL = URL(fileURLWithPath: a[4])
let outURL = URL(fileURLWithPath: a[5])
let W = a.count > 7 ? Int(a[6])! : 1920
let H = a.count > 7 ? Int(a[7])! : 1080

let names = try FileManager.default.contentsOfDirectory(atPath: dir.path)
    .filter { $0.hasPrefix(prefix) && $0.hasSuffix(".png") }
    .sorted()
print("frames: \(names.count)")
try? FileManager.default.removeItem(at: outURL)

let writer = try AVAssetWriter(outputURL: outURL, fileType: .mp4)
let vIn = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: W,
    AVVideoHeightKey: H,
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: Int(ProcessInfo.processInfo.environment["BITRATE"] ?? "") ?? 10_000_000,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
        AVVideoMaxKeyFrameIntervalKey: Int(fps) * 2,
    ],
])
vIn.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: vIn, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferWidthKey as String: W,
    kCVPixelBufferHeightKey as String: H,
])
writer.add(vIn)

let asset = AVURLAsset(url: audioURL)
let aTrack = asset.tracks(withMediaType: .audio).first!
let reader = try AVAssetReader(asset: asset)
let rOut = AVAssetReaderTrackOutput(track: aTrack, outputSettings: [
    AVFormatIDKey: kAudioFormatLinearPCM,
    AVLinearPCMBitDepthKey: 16,
    AVLinearPCMIsFloatKey: false,
    AVLinearPCMIsBigEndianKey: false,
    AVLinearPCMIsNonInterleaved: false,
])
reader.add(rOut)
let aIn = AVAssetWriterInput(mediaType: .audio, outputSettings: [
    AVFormatIDKey: kAudioFormatMPEG4AAC,
    AVSampleRateKey: 44100,
    AVNumberOfChannelsKey: 2,
    AVEncoderBitRateKey: 192_000,
])
aIn.expectsMediaDataInRealTime = false
writer.add(aIn)

guard writer.startWriting() else { print("writer error: \(String(describing: writer.error))"); exit(1) }
reader.startReading()
writer.startSession(atSourceTime: .zero)

let group = DispatchGroup()
let cs = CGColorSpaceCreateDeviceRGB()

group.enter()
var frameIdx = 0
vIn.requestMediaDataWhenReady(on: DispatchQueue(label: "video")) {
    while vIn.isReadyForMoreMediaData {
        if frameIdx >= names.count {
            vIn.markAsFinished()
            group.leave()
            return
        }
        autoreleasepool {
            let url = dir.appendingPathComponent(names[frameIdx])
            guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
                print("bad frame \(names[frameIdx])"); exit(1)
            }
            var pb: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
            let buf = pb!
            CVPixelBufferLockBaseAddress(buf, [])
            let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buf), width: W, height: H, bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buf), space: cs,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
            ctx.interpolationQuality = .none
            ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
            ctx.draw(img, in: CGRect(x: 0, y: 0, width: W, height: H))
            CVPixelBufferUnlockBaseAddress(buf, [])
            adaptor.append(buf, withPresentationTime: CMTime(value: CMTimeValue(frameIdx), timescale: fps))
            frameIdx += 1
        }
    }
}

group.enter()
aIn.requestMediaDataWhenReady(on: DispatchQueue(label: "audio")) {
    while aIn.isReadyForMoreMediaData {
        if let sb = rOut.copyNextSampleBuffer() {
            aIn.append(sb)
        } else {
            aIn.markAsFinished()
            group.leave()
            return
        }
    }
}

group.wait()
let done = DispatchSemaphore(value: 0)
writer.finishWriting { done.signal() }
done.wait()
if writer.status != .completed {
    print("failed: \(String(describing: writer.error))")
    exit(1)
}
print("wrote \(outURL.path)")
