import AVFoundation
import Photos

/// RecordingManager: AVAssetWriter pipeline for Apple Log recording
class RecordingManager: NSObject, ObservableObject,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureAudioDataOutputSampleBufferDelegate {

    // MARK: - Published State
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var savedSessions: [RecordingSession] = []

    // MARK: - Private
    private var assetWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var sessionStartTime: CMTime = .invalid
    private var timer: Timer?

    // MARK: - Camera Manager Reference
    weak var cameraManager: CameraManager?

    // MARK: - Start Recording
    func startRecording(isAppleLog: Bool, resolution: Resolution, fps: FrameRate) {
        guard !isRecording else { return }

        let outputURL = makeOutputURL()

        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        } catch {
            print("AssetWriter init error: \(error)")
            return
        }

        // --- Video Settings ---
        var compressionProps: [String: Any] = [
            AVVideoAverageBitRateKey: videoBitrate(resolution: resolution, fps: fps),
            AVVideoAllowFrameReorderingKey: false
        ]

        var colorProperties: [String: Any] = [:]
        if isAppleLog {
            colorProperties = [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_P3_D65,
                AVVideoTransferFunctionKey: "AppleLog",
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020
            ]
        } else {
            colorProperties = [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
            ]
        }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: resolution.width,
            AVVideoHeightKey: resolution.height,
            AVVideoCompressionPropertiesKey: compressionProps,
            AVVideoColorPropertiesKey: colorProperties
        ]

        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput?.expectsMediaDataInRealTime = true

        // --- Audio Settings ---
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 256_000
        ]

        audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioWriterInput?.expectsMediaDataInRealTime = true

        guard let writer = assetWriter,
              let vInput = videoWriterInput,
              let aInput = audioWriterInput else { return }

        if writer.canAdd(vInput) { writer.add(vInput) }
        if writer.canAdd(aInput) { writer.add(aInput) }

        writer.startWriting()
        sessionStartTime = .invalid

        DispatchQueue.main.async {
            self.isRecording = true
            self.recordingDuration = 0
        }

        // Start duration timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            DispatchQueue.main.async {
                self.recordingDuration += 0.1
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    // MARK: - Stop Recording
    func stopRecording(isAppleLog: Bool, resolution: Resolution, fps: FrameRate) {
        guard isRecording else { return }

        timer?.invalidate()
        timer = nil

        videoWriterInput?.markAsFinished()
        audioWriterInput?.markAsFinished()

        let finalDuration = recordingDuration
        let outputURL = assetWriter?.outputURL

        assetWriter?.finishWriting { [weak self] in
            guard let self = self, let url = outputURL else { return }

            // Save to Photos Library
            self.saveToPhotoLibrary(url: url)

            let session = RecordingSession(
                url: url,
                duration: finalDuration,
                date: Date(),
                isAppleLog: isAppleLog,
                resolution: resolution.rawValue,
                fps: fps.rawValue
            )

            DispatchQueue.main.async {
                self.isRecording = false
                self.savedSessions.insert(session, at: 0)
                self.recordingDuration = 0
                self.assetWriter = nil
                self.videoWriterInput = nil
                self.audioWriterInput = nil
                self.sessionStartTime = .invalid
            }
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard isRecording, let writer = assetWriter else { return }

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        if sessionStartTime == .invalid {
            writer.startSession(atSourceTime: presentationTime)
            sessionStartTime = presentationTime
        }

        if output is AVCaptureVideoDataOutput {
            if videoWriterInput?.isReadyForMoreMediaData == true {
                videoWriterInput?.append(sampleBuffer)
            }
        } else if output is AVCaptureAudioDataOutput {
            if audioWriterInput?.isReadyForMoreMediaData == true {
                audioWriterInput?.append(sampleBuffer)
            }
        }
    }

    // MARK: - Helpers
    private func makeOutputURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "LogCam_\(formatter.string(from: Date())).mov"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(filename)
    }

    private func videoBitrate(resolution: Resolution, fps: FrameRate) -> Int {
        switch (resolution, fps) {
        case (.uhd4k, .fps60): return 200_000_000
        case (.uhd4k, .fps30): return 130_000_000
        case (.uhd4k, .fps24): return 100_000_000
        case (.fhd1080, .fps60): return 60_000_000
        case (.fhd1080, .fps30): return 40_000_000
        default: return 25_000_000
        }
    }

    private func saveToPhotoLibrary(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                if let error = error {
                    print("Photo library save error: \(error)")
                }
            }
        }
    }
}
