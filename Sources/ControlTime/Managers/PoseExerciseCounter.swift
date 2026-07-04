import Foundation
import AVFoundation
import Vision
import Combine
import CoreGraphics

/// Считает повторения через фронтальную камеру + Apple Vision Body Pose.
/// Телефон ставится перед пользователем (на стол/стул).
///
/// Логика подсчёта:
/// - Приседания: угол в колене < downThreshold → фаза DOWN; угол > upThreshold → фаза UP → +1 rep
/// - Отжимания: угол в локте < downThreshold → фаза DOWN; угол > upThreshold → фаза UP → +1 rep
@MainActor
final class PoseExerciseCounter: NSObject, ObservableObject {
    @Published var count = 0
    @Published var isRunning = false
    @Published var cameraAccessDenied = false
    @Published var debugAngle: Double = 0
    @Published var skeletonPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

    let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private var request: VNDetectHumanBodyPoseRequest?
    private var sequenceHandler = VNSequenceRequestHandler()

    private var phase: Phase = .up
    private var exerciseType: ExerciseType = .squats
    private var target = 0
    private var onComplete: (() -> Void)?

    private var sessionQueue = DispatchQueue(label: "pose.session", qos: .userInteractive)

    private enum Phase { case up, down }

    // Пороги угла (в градусах) — можно подстраивать под пользователя
    private let squatDownThreshold: Double = 120   // ноги согнуты
    private let squatUpThreshold: Double = 155     // ноги выпрямлены
    private let pushupDownThreshold: Double = 95   // локти согнуты
    private let pushupUpThreshold: Double = 140    // руки выпрямлены

    func start(exerciseType: ExerciseType, target: Int, onComplete: @escaping () -> Void) {
        self.exerciseType = exerciseType
        self.target = target
        self.onComplete = onComplete
        self.count = 0
        self.phase = .up

        Task { await checkCameraPermissionAndStart() }
    }

    func stop() {
        isRunning = false
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func addManualRep() {
        registerRep()
    }

    // MARK: - Camera setup

    private func checkCameraPermissionAndStart() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await startSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted { await startSession() } else { cameraAccessDenied = true }
        default:
            cameraAccessDenied = true
        }
    }

    private func startSession() async {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else { continuation.resume(); return }
                self.configureSession()
                self.session.startRunning()
                Task { @MainActor in
                    self.isRunning = true
                }
                continuation.resume()
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration(); return
        }
        session.addInput(input)

        output.setSampleBufferDelegate(self, queue: sessionQueue)
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }

        if let connection = output.connection(with: .video) {
            if #available(iOS 17.0, *) {
                connection.videoRotationAngle = 90
            } else {
                connection.videoOrientation = .portrait
            }
        }

        session.commitConfiguration()
    }

    // MARK: - Pose analysis

    private nonisolated func analyze(pixelBuffer: CVPixelBuffer) {
        let req = VNDetectHumanBodyPoseRequest()
        try? sequenceHandler.perform([req], on: pixelBuffer, orientation: .right)

        guard let observation = req.results?.first else { return }

        let allJoints: [VNHumanBodyPoseObservation.JointName] = [
            .neck, .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow, .leftWrist, .rightWrist,
            .leftHip, .rightHip, .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle,
        ]
        var pts: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for joint in allJoints {
            if let p = point(observation, joint) { pts[joint] = p }
        }

        let angle: Double?
        switch exerciseType {
        case .squats:       angle = kneeAngle(from: observation)
        case .pushups:      angle = elbowAngle(from: observation)
        case .jumpingJacks: angle = shoulderAbductionAngle(from: observation)
        }

        guard let a = angle else {
            Task { @MainActor [weak self] in self?.skeletonPoints = pts }
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.debugAngle = a
            self.skeletonPoints = pts
            self.updatePhase(angle: a)
        }
    }

    private func updatePhase(angle: Double) {
        let downT: Double
        let upT: Double
        switch exerciseType {
        case .squats:       downT = squatDownThreshold;  upT = squatUpThreshold
        case .pushups:      downT = pushupDownThreshold; upT = pushupUpThreshold
        case .jumpingJacks: downT = 80;                  upT = 30
        }

        switch phase {
        case .up:
            if angle < downT { phase = .down }
        case .down:
            if angle > upT { phase = .up; registerRep() }
        }
    }

    private func registerRep() {
        count += 1
        if count >= target {
            stop()
            onComplete?()
        }
    }

    // MARK: - Angle calculations

    private func kneeAngle(from obs: VNHumanBodyPoseObservation) -> Double? {
        // Предпочитаем левую ногу, fallback на правую
        let hip   = point(obs, .leftHip)   ?? point(obs, .rightHip)
        let knee  = point(obs, .leftKnee)  ?? point(obs, .rightKnee)
        let ankle = point(obs, .leftAnkle) ?? point(obs, .rightAnkle)
        guard let h = hip, let k = knee, let a = ankle else { return nil }
        return angle(at: k, from: h, to: a)
    }

    private func elbowAngle(from obs: VNHumanBodyPoseObservation) -> Double? {
        let shoulder = point(obs, .leftShoulder) ?? point(obs, .rightShoulder)
        let elbow    = point(obs, .leftElbow)    ?? point(obs, .rightElbow)
        let wrist    = point(obs, .leftWrist)    ?? point(obs, .rightWrist)
        guard let s = shoulder, let e = elbow, let w = wrist else { return nil }
        return angle(at: e, from: s, to: w)
    }

    private func shoulderAbductionAngle(from obs: VNHumanBodyPoseObservation) -> Double? {
        // Для джампинг-джека смотрим угол разведения рук (плечо–корень шеи–плечо)
        guard let l = point(obs, .leftShoulder),
              let r = point(obs, .rightShoulder),
              let neck = point(obs, .neck) else { return nil }
        return angle(at: neck, from: l, to: r)
    }

    private func point(_ obs: VNHumanBodyPoseObservation, _ jointName: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
        guard let recognized = try? obs.recognizedPoint(jointName),
              recognized.confidence > 0.3 else { return nil }
        return CGPoint(x: recognized.location.x, y: recognized.location.y)
    }

    /// Угол в вершине `vertex` между лучами vertex→a и vertex→b (в градусах)
    private func angle(at vertex: CGPoint, from a: CGPoint, to b: CGPoint) -> Double {
        let v1 = CGVector(dx: a.x - vertex.x, dy: a.y - vertex.y)
        let v2 = CGVector(dx: b.x - vertex.x, dy: b.y - vertex.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let mag = sqrt(v1.dx*v1.dx + v1.dy*v1.dy) * sqrt(v2.dx*v2.dx + v2.dy*v2.dy)
        guard mag > 0 else { return 0 }
        return Double(acos(Float(max(-1, min(1, dot / mag))))) * 180 / .pi
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension PoseExerciseCounter: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        analyze(pixelBuffer: pixelBuffer)
    }
}
