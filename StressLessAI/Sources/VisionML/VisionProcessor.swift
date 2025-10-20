import Vision
import CoreMedia
import CoreGraphics

final class VisionProcessor {
    static let shared = VisionProcessor()
    private let rectReq = VNDetectFaceRectanglesRequest()
    private let lmReq   = VNDetectFaceLandmarksRequest()
    private var lastBox: CGRect?
    private var blinkHist: [(t: TimeInterval, ear: Double)] = []
    private var lastClosedAt: TimeInterval?
    private let exif: CGImagePropertyOrientation = .upMirrored

    func process(pixelBuffer: CVPixelBuffer, at pts: CMTime) {
        let ts = pts.seconds
        let w = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let h = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imgSize = CGSize(width: w, height: h)
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exif, options: [:])

        do { try handler.perform([rectReq]) } catch { return }
        guard let first = rectReq.results?.first else {
            DispatchQueue.main.async { FaceBoxOverlayState.shared.box = .null }
            return
        }

        let vb = first.boundingBox
        let meta = CGRect(x: vb.origin.x, y: 1 - vb.origin.y - vb.size.height, width: vb.size.width, height: vb.size.height)
        DispatchQueue.main.async { FaceBoxOverlayState.shared.box = meta }

        lmReq.inputFaceObservations = [first]
        do { try handler.perform([lmReq]) } catch { return }
        guard let face = lmReq.results?.first, let L = face.landmarks else { return }

        let LE = L.leftEye?.pointsInImage(imageSize: imgSize) ?? []
        let RE = L.rightEye?.pointsInImage(imageSize: imgSize) ?? []
        let inner = L.innerLips?.pointsInImage(imageSize: imgSize) ?? []
        let outer = L.outerLips?.pointsInImage(imageSize: imgSize) ?? []
        let mouthPts = inner.isEmpty ? outer : inner

        let ear = (eyeEAR(LE) + eyeEAR(RE)) * 0.5
        var blinkNow = false
        let closed = ear < 0.30
        if closed { if lastClosedAt == nil { lastClosedAt = ts } }
        else if let t0 = lastClosedAt { if ts - t0 <= 0.30 { blinkNow = true }; lastClosedAt = nil }
        blinkHist.append((ts, ear))
        blinkHist = blinkHist.filter { ts - $0.t <= 10 }
        let blinkPM = Double(blinkHist.indices.dropFirst().filter { (blinkHist[$0-1].ear < 0.30) && (blinkHist[$0].ear >= 0.30) }.count) * 6.0
        _ = blinkNow

        let mouth = mouthOpen(mouthPts)
        let jit = jitter(cur: first.boundingBox, prev: lastBox, img: imgSize)
        lastBox = first.boundingBox

        let stress = StressEngine.shared.score(blinkPM: blinkPM, mouth: mouth, jitter: jit)
        StressEngine.shared.handle(stress: stress, ts: ts)

        DispatchQueue.main.async {
            TelemetryStore.shared.push(FaceTelemetry(ts: ts, blinkPM: blinkPM, mouthOpen: mouth, jitter: jit, stress: stress, box: first.boundingBox))
        }
    }

    private func eyeEAR(_ pts: [CGPoint]) -> Double {
        guard pts.count >= 4 else { return 0 }
        let left  = pts.min(by: { $0.x < $1.x })!
        let right = pts.max(by: { $0.x < $1.x })!
        var top = pts[0], bottom = pts[0]; var maxH: CGFloat = 0
        for i in 0..<pts.count { for j in (i+1)..<pts.count {
            let dh = abs(pts[i].y - pts[j].y)
            if dh > maxH { maxH = dh; top = pts[i].y < pts[j].y ? pts[i] : pts[j]; bottom = pts[i].y < pts[j].y ? pts[j] : pts[i] }
        }}
        let horiz = max(hypot(left.x - right.x, left.y - right.y), 1e-3)
        let vert  = hypot(top.x - bottom.x, top.y - bottom.y)
        return Double(vert / horiz)
    }

    private func mouthOpen(_ pts: [CGPoint]) -> Double {
        guard pts.count >= 4 else { return 0 }
        let left  = pts.min(by: { $0.x < $1.x })!
        let right = pts.max(by: { $0.x < $1.x })!
        var top = pts[0], bottom = pts[0]; var maxH: CGFloat = 0
        for i in 0..<pts.count { for j in (i+1)..<pts.count {
            let dh = abs(pts[i].y - pts[j].y)
            if dh > maxH { maxH = dh; top = pts[i].y < pts[j].y ? pts[i] : pts[j]; bottom = pts[i].y < pts[j].y ? pts[j] : pts[i] }
        }}
        let width  = max(hypot(left.x - right.x, left.y - right.y), 1e-6)
        let height = hypot(top.x - bottom.x, top.y - bottom.y)
        let ratio = Double(height / width)
        return min(max((ratio - 0.20) * (100.0 / (0.45 - 0.20)), 0), 100)
    }

    private func jitter(cur: CGRect, prev: CGRect?, img: CGSize) -> Double {
        guard let p = prev else { return 0 }
        let cx = cur.midX * img.width, cy = cur.midY * img.height
        let px = p.midX * img.width,  py = p.midY * img.height
        let dist = hypot(Double(cx - px), Double(cy - py))
        let diag = hypot(Double(img.width), Double(img.height))
        return min(dist / (diag * 0.01) * 5.0, 100.0)
    }
}
