import AVFoundation
import Combine

/// CameraManager: AVCaptureSession setup + Apple Log format detection
class CameraManager: NSObject, ObservableObject {

    // MARK: - Published State
    @Published var isAppleLogSupported = false
    @Published var isAppleLogEnabled = false
    @Published var isSessionRunning = false
    @Published var errorMessage: String?
    @Published var selectedResolution: Resolution = .uhd4k
    @Published var selectedFPS: FrameRate = .fps30

    // MARK: - AVFoundation
    let session = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private(set) var videoDataOutput = AVCaptureVideoDataOutput()
    private(set) var audioDataOutput = AVCaptureAudioDataOutput()

    // MARK: - Queues
    let sessionQueue = DispatchQueue(label: "com.logcam.session", qos: .userInitiated)
    let videoOutputQueue = DispatchQueue(label: "com.logcam.videooutput", qos: .userInitiated)

    // MARK: - Delegate
    weak var sampleBufferDelegate: (AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate)?

    // MARK: - Setup
    func configure() {
        sessionQueue.async { [weak self] in
            self?.setupSession()
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .inputPriority

        // 1. Select camera device
        guard let device = selectBestCamera() else {
            DispatchQueue.main.async { self.errorMessage = "No suitable camera found." }
            session.commitConfiguration()
            return
        }
        videoDevice = device

        // 2. Add video input
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                DispatchQueue.main.async { self.errorMessage = "Cannot add camera input." }
                session.commitConfiguration()
                return
            }
            session.addInput(input)
            videoInput = input
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            session.commitConfiguration()
            return
        }

        // 3. Add audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        // 4. Add video data output
        videoDataOutput.alwaysDiscardsLateVideoFrames = false
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
        ]
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }

        // 5. Add audio data output
        if session.canAddOutput(audioDataOutput) {
            session.addOutput(audioDataOutput)
        }

        // 6. Check Apple Log support
        let logSupported = checkAppleLogSupport(device: device)
        DispatchQueue.main.async {
            self.isAppleLogSupported = logSupported
        }

        // 7. Configure format (resolution + fps + Apple Log)
        configureDeviceFormat(device: device, appleLog: false)

        session.commitConfiguration()

        // 8. Start session
        session.startRunning()
        DispatchQueue.main.async {
            self.isSessionRunning = self.session.isRunning
        }
    }

    // MARK: - Camera Selection
    private func selectBestCamera() -> AVCaptureDevice? {
        // Prefer main wide camera on Pro models
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualWideCamera, .builtInTripleCamera],
            mediaType: .video,
            position: .back
        )
        return discoverySession.devices.first
    }

    // MARK: - Apple Log Detection
    private func checkAppleLogSupport(device: AVCaptureDevice) -> Bool {
        return device.formats.contains { format in
            format.supportedColorSpaces.contains(.appleLog)
        }
    }

    // MARK: - Format Configuration
    func configureDeviceFormat(device: AVCaptureDevice, appleLog: Bool) {
        let targetWidth = selectedResolution.width
        let targetHeight = selectedResolution.height
        let targetFPS = selectedFPS.rawValue

        // Find best matching format
        let candidates = device.formats.filter { format in
            let desc = format.formatDescription
            let dims = CMVideoFormatDescriptionGetDimensions(desc)
            let fpsRanges = format.videoSupportedFrameRateRanges
            let supportsFPS = fpsRanges.contains { $0.maxFrameRate >= Double(targetFPS) }
            let supportsLog = appleLog ? format.supportedColorSpaces.contains(.appleLog) : true
            return Int(dims.width) == targetWidth && supportsLog && supportsFPS
        }

        guard let bestFormat = candidates.first else {
            // Fallback: find any Apple Log format
            let fallback = device.formats.first { f in
                appleLog ? f.supportedColorSpaces.contains(.appleLog) : true
            }
            guard let f = fallback else { return }
            applyFormat(device: device, format: f, fps: targetFPS, appleLog: appleLog)
            return
        }

        applyFormat(device: device, format: bestFormat, fps: targetFPS, appleLog: appleLog)
    }

    private func applyFormat(device: AVCaptureDevice, format: AVCaptureDevice.Format, fps: Int, appleLog: Bool) {
        do {
            try device.lockForConfiguration()
            device.activeFormat = format
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))

            if appleLog && format.supportedColorSpaces.contains(.appleLog) {
                device.activeColorSpace = .appleLog
            } else {
                device.activeColorSpace = .sRGB
            }

            device.unlockForConfiguration()

            DispatchQueue.main.async {
                self.isAppleLogEnabled = appleLog && format.supportedColorSpaces.contains(.appleLog)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Format config error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Toggle Apple Log
    func toggleAppleLog() {
        guard let device = videoDevice, isAppleLogSupported else { return }
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureDeviceFormat(device: device, appleLog: !self.isAppleLogEnabled)
        }
    }

    // MARK: - Delegates
    func setOutputDelegate(delegate: AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate) {
        videoDataOutput.setSampleBufferDelegate(delegate, queue: videoOutputQueue)
        audioDataOutput.setSampleBufferDelegate(delegate, queue: videoOutputQueue)
        sampleBufferDelegate = delegate
    }

    // MARK: - Stop
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
}
