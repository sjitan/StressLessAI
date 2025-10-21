import AVFoundation
import AppKit

final class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let shared = CameraManager()

    private let session = AVCaptureSession()
    private var input: AVCaptureDeviceInput?
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "ai.stressless.capture")
    let previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    private let fps: Int32 = 24
    private var configured = false

    override init() {
        super.init()
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.session = session
        NotificationCenter.default.addObserver(self, selector: #selector(recover(_:)), name: AVCaptureSession.runtimeErrorNotification, object: session)
    }

    func configure() {
        guard !configured else { return }
        configured = true
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        if let i = input { session.removeInput(i) }
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified)
            ?? AVCaptureDevice.default(.external, for: .video, position: .unspecified)
        else { session.commitConfiguration(); configured = false; return }

        do {
            let i = try AVCaptureDeviceInput(device: dev)
            if session.canAddInput(i) { session.addInput(i); input = i }
            try dev.lockForConfiguration()
            if let r = dev.activeFormat.videoSupportedFrameRateRanges.first {
                let f = min(max(Int32(r.minFrameRate), fps), Int32(r.maxFrameRate))
                dev.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(f))
                dev.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(f))
            }
            dev.unlockForConfiguration()
        } catch { session.commitConfiguration(); configured = false; return }

        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }
        if let c = output.connection(with: .video) { c.isVideoMirrored = true; c.automaticallyAdjustsVideoMirroring = true }
        session.commitConfiguration()
    }

    func start() {
        CameraPermission.request { granted in
            DispatchQueue.main.async {
                guard granted else { return }
                if !self.configured { self.configure() }
                if !self.session.isRunning { self.session.startRunning() }
            }
        }
    }
    func stop(){ if session.isRunning { session.stopRunning() } }

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sb: CMSampleBuffer, from: AVCaptureConnection) {
        guard let pb = CMSampleBufferGetImageBuffer(sb) else { return }
        let ts = CMSampleBufferGetPresentationTimeStamp(sb)
        VisionProcessor.shared.process(pixelBuffer: pb, at: ts)
    }

    @objc private func recover(_ n: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2){ self.configured = false; self.start() }
    }
}
