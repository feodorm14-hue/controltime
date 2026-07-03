import SwiftUI
import Vision

struct PoseOverlayView: View {
    let points: [VNHumanBodyPoseObservation.JointName: CGPoint]

    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
    ]

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let w = size.width
                let h = size.height

                func screenPt(_ p: CGPoint) -> CGPoint {
                    // Vision: origin bottom-left, Y up; screen: origin top-left, Y down
                    // Front camera is mirrored horizontally, so flip X too
                    CGPoint(x: (1 - p.x) * w, y: (1 - p.y) * h)
                }

                // Lines
                for (a, b) in connections {
                    guard let pa = points[a], let pb = points[b] else { continue }
                    var path = Path()
                    path.move(to: screenPt(pa))
                    path.addLine(to: screenPt(pb))
                    ctx.stroke(path, with: .color(.white.opacity(0.85)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                // Joints
                for (_, pt) in points {
                    let sp = screenPt(pt)
                    let rect = CGRect(x: sp.x - 5, y: sp.y - 5, width: 10, height: 10)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.green))
                }
            }
        }
    }
}
