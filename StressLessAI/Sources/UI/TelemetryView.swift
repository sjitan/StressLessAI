import SwiftUI
import AVFoundation
import Vision

struct TelemetryView: View {
    let cam = CameraManager.shared
    @ObservedObject var store = TelemetryStore.shared

    var body: some View {
        ZStack {
            PreviewContainer(layer: cam.previewLayer)
            FaceBoxOverlay(previewLayer: cam.previewLayer).allowsHitTesting(false)
            HUD
        }
    }

    private var HUD: some View {
        let t = store.latest
        return VStack(alignment:.leading, spacing:6) {
            Text(String(format:"Stress: %.0f", t?.stress ?? 0))
            Text(String(format:"BlinkPM: %.1f  Mouth: %.0f  Jitter: %.0f",
                        t?.blinkPM ?? 0, t?.mouthOpen ?? 0, t?.jitter ?? 0))
        }
        .padding(8).background(.ultraThinMaterial).cornerRadius(8).padding()
    }
}

// NSView that always keeps the preview layer sized to its bounds.
final class PreviewHostView: NSView {
    private weak var preview: AVCaptureVideoPreviewLayer?
    init(preview: AVCaptureVideoPreviewLayer) {
        self.preview = preview
        super.init(frame: .zero)
        wantsLayer = true
        preview.removeFromSuperlayer()
        layer?.addSublayer(preview)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layout() {
        super.layout()
        preview?.frame = bounds
    }
}

struct PreviewContainer: NSViewRepresentable {
    let layer: AVCaptureVideoPreviewLayer
    func makeNSView(context: Context) -> NSView { PreviewHostView(preview: layer) }
    func updateNSView(_ v: NSView, context: Context) { v.needsLayout = true }
}

final class FaceBoxOverlayState: ObservableObject { static let shared = FaceBoxOverlayState(); @Published var box = CGRect.null }

struct FaceBoxOverlay: NSViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    @ObservedObject var state = FaceBoxOverlayState.shared
    func makeNSView(context: Context) -> NSView { let v = NSView(); v.wantsLayer = true; v.layer = CAShapeLayer(); return v }
    func updateNSView(_ v: NSView, context: Context) {
        guard let l = v.layer as? CAShapeLayer else { return }
        let path = CGMutablePath()
        if !state.box.isNull { path.addRect(previewLayer.layerRectConverted(fromMetadataOutputRect: state.box)) }
        l.path = path; l.fillColor = NSColor.clear.cgColor
        l.strokeColor = NSColor.systemGreen.cgColor; l.lineWidth = 2
    }
}
