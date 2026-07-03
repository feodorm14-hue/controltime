import SwiftUI
import AVFoundation

/// UIViewRepresentable-обёртка над AVCaptureVideoPreviewLayer.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    final class PreviewUIView: UIView {
        var session: AVCaptureSession? {
            didSet { previewLayer.session = session }
        }

        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        private var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = bounds
        }
    }
}
