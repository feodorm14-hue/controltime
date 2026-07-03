import SwiftUI

struct ExerciseView: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @StateObject private var counter = PoseExerciseCounter()
    @Environment(\.dismiss) private var dismiss
    @State private var isDone = false

    private var target: Int { manager.repsPerInterval }

    var body: some View {
        ZStack {
            // Камера на весь экран
            CameraPreviewView(session: counter.session)
                .ignoresSafeArea()

            // Скелет поверх камеры
            PoseOverlayView(points: counter.skeletonPoints)
                .ignoresSafeArea()

            // Затемнение снизу для удобства чтения текста
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                // Заголовок сверху
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(manager.exerciseType.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        if !counter.cameraAccessDenied {
                            Text("Угол: \(Int(counter.debugAngle))°")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    Spacer()
                    if manager.graceSkipsRemaining > 0 {
                        Button {
                            _ = manager.useGraceSkip()
                            dismiss()
                        } label: {
                            Text("Пропустить (\(manager.graceSkipsRemaining))")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial.opacity(0.7))

                Spacer()

                // Счётчик + прогресс снизу
                VStack(spacing: 20) {
                    if counter.cameraAccessDenied {
                        cameraAccessDeniedView
                    } else {
                        repCounterView
                    }

                    Button {
                        counter.addManualRep()
                        checkDone()
                    } label: {
                        Label("Засчитать вручную", systemImage: "hand.tap")
                            .font(.footnote)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .interactiveDismissDisabled(true)
        .statusBarHidden()
        .onAppear {
            counter.start(exerciseType: manager.exerciseType, target: target, onComplete: finish)
        }
        .onDisappear {
            counter.stop()
        }
        .onChange(of: counter.count) { _, _ in checkDone() }
    }

    // MARK: - Sub-views

    private var repCounterView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.green, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.3), value: progress)
                Text("\(counter.count)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 180, height: 180)

            Text("из \(target) повторений")
                .font(.title3)
                .foregroundStyle(.white)

            Text("Поставь телефон перед собой,\nчтобы камера видела тело целиком")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var cameraAccessDeniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.slash")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.7))
            Text("Нет доступа к камере")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Разреши доступ в Настройки → Конфиденциальность → Камера, либо засчитывай повторения кнопкой вручную.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.7))
            Button("Открыть настройки") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(.white)

            // В режиме без камеры показываем простой счётчик
            Text("\(counter.count) / \(target)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1, Double(counter.count) / Double(target))
    }

    private func checkDone() {
        if counter.count >= target && !isDone { finish() }
    }

    private func finish() {
        guard !isDone else { return }
        isDone = true
        HistoryStore.shared.append(
            ExerciseSession(
                id: UUID(),
                date: Date(),
                exerciseType: manager.exerciseType,
                repsCompleted: target,
                minutesUnlocked: manager.intervalMinutes
            )
        )
        manager.rewardUnlock()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}
