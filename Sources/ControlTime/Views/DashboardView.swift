import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @State private var showExercise = false
    @State private var showShortcutsGuide = false
    @State private var showAppPicker = false

    var body: some View {
        NavigationStack {
            Form {
                graceSkipSection
                settingsSection
                monitoringSection
                appsSection
                bottomSection
            }
            .navigationTitle("ControlTime")
            .sheet(isPresented: $showExercise) {
                ExerciseView()
                    .environmentObject(manager)
            }
            .sheet(isPresented: $showShortcutsGuide) {
                ShortcutsGuideSheet()
            }
            .sheet(isPresented: $showAppPicker) {
                AppPickerView(selectedApps: $manager.trackedApps)
                    .onDisappear { manager.persistSettings() }
            }
        }
    }

    private var graceSkipSection: some View {
        Section {
            HStack {
                Label("Пропусков осталось", systemImage: "hand.raised")
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i < manager.graceSkipsRemaining ? Color.orange : Color.secondary.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
            }
        } footer: {
            Text("4 пропуска в день — можешь пропустить упражнение и получить ещё \(manager.intervalMinutes) мин.")
        }
    }

    private var settingsSection: some View {
        Section("Условия разблокировки") {
            Stepper("Интервал: \(manager.intervalMinutes) мин", value: $manager.intervalMinutes, in: 1...120)
            Stepper("\(manager.repsPerInterval) повторений", value: $manager.repsPerInterval, in: 1...100)
            Picker("Упражнение", selection: $manager.exerciseType) {
                ForEach(ExerciseType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
        }
        .onChange(of: manager.intervalMinutes) { _, _ in manager.persistSettings() }
        .onChange(of: manager.repsPerInterval) { _, _ in manager.persistSettings() }
        .onChange(of: manager.exerciseType) { _, _ in manager.persistSettings() }
    }

    private var monitoringSection: some View {
        Section {
            Toggle("Контроль включён", isOn: Binding(
                get: { manager.isMonitoringActive },
                set: { newValue in
                    if newValue { manager.startMonitoring() } else { manager.stopMonitoring() }
                }
            ))
            Button {
                showExercise = true
            } label: {
                Label("Сделать упражнение сейчас", systemImage: "figure.run")
            }
        } footer: {
            Text("Когда включено, уведомление придёт через \(manager.intervalMinutes) мин и после каждого упражнения.")
        }
    }

    private var appsSection: some View {
        Section {
            Button {
                showAppPicker = true
            } label: {
                HStack {
                    Label("Выбрать приложения", systemImage: "app.badge")
                    Spacer()
                    Text(manager.trackedApps.isEmpty ? "не выбрано" : "\(manager.trackedApps.count) шт.")
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            if !manager.trackedApps.isEmpty {
                ForEach(manager.trackedApps, id: \.self) { app in
                    Text(app)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .onDelete { indices in
                    manager.trackedApps.remove(atOffsets: indices)
                    manager.persistSettings()
                }
            }
        } header: {
            Text("Приложения под контролем")
        } footer: {
            Text("После выбора настрой автоматизацию в Shortcuts для каждого — кнопка ниже.")
        }
    }

    private var bottomSection: some View {
        Section {
            Button {
                showShortcutsGuide = true
            } label: {
                Label("Как настроить Shortcuts", systemImage: "arrow.triangle.2.circlepath")
            }
            NavigationLink("История") {
                HistoryView()
            }
        }
    }
}

struct ShortcutsGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Настрой один раз для каждого приложения, которое хочешь ограничить:")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    steps
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Важно")
                            .font(.headline)
                        Text("• Сними галочку «Спрашивать перед запуском» — иначе автоматизация будет просить подтверждение.\n• Одна автоматизация = одно приложение.\n• Если ControlTime уже открыт, iOS просто переключится на него.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Настройка Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 12) {
            step("1", "Открой приложение «Быстрые команды»")
            step("2", "Вкладка «Автоматизация» → «+»")
            step("3", "Выбери «Приложение»")
            step("4", "Нажми «Выбрать» и выбери нужное приложение")
            step("5", "Отметь «При открытии», нажми «Далее»")
            step("6", "Нажми «Новая пустая автоматизация»")
            step("7", "Добавь действие «Открыть URL»")
            step("8", "В поле URL введи: controltime://unlock")
            step("9", "Сохрани и сними галку «Спрашивать»")
        }
    }

    private func step(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n)
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.green)
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}
