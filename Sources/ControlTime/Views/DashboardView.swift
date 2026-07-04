import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @State private var showExercise = false
    @State private var showShortcutsGuide = false
    @State private var showAppPicker = false
    @State private var showPinSetup = false
    @State private var showPinEntry = false

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
                ExerciseView().environmentObject(manager)
            }
            .sheet(isPresented: $showShortcutsGuide) {
                ShortcutsGuideSheet()
            }
            .sheet(isPresented: $showAppPicker) {
                AppPickerView(selectedApps: $manager.trackedApps)
                    .onDisappear { manager.persistSettings() }
            }
            .sheet(isPresented: $showPinSetup) {
                PinSetupSheet().environmentObject(manager)
            }
            .sheet(isPresented: $showPinEntry) {
                PinEntrySheet { success in
                    if success { manager.stopMonitoring() }
                }
                .environmentObject(manager)
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
        .onChange(of: manager.intervalMinutes) { _ in manager.persistSettings() }
        .onChange(of: manager.repsPerInterval) { _ in manager.persistSettings() }
        .onChange(of: manager.exerciseType) { _ in manager.persistSettings() }
    }

    private var monitoringSection: some View {
        Section {
            HStack {
                Label("Контроль включён", systemImage: manager.isMonitoringActive ? "lock.fill" : "lock.open")
                    .foregroundStyle(manager.isMonitoringActive ? .green : .primary)
                Spacer()
                if manager.isMonitoringActive {
                    Button("Выключить") {
                        if manager.monitoringPin != nil {
                            showPinEntry = true
                        } else {
                            manager.stopMonitoring()
                        }
                    }
                    .foregroundStyle(.red)
                    .buttonStyle(.plain)
                } else {
                    Button("Включить") {
                        if manager.monitoringPin == nil {
                            showPinSetup = true
                        } else {
                            manager.startMonitoring()
                        }
                    }
                    .foregroundStyle(.green)
                    .buttonStyle(.plain)
                }
            }

            Button {
                showExercise = true
            } label: {
                Label("Сделать упражнение сейчас", systemImage: "figure.run")
            }

            if manager.monitoringPin != nil {
                Button(role: .destructive) {
                    showPinEntry = true
                } label: {
                    Label("Сменить PIN", systemImage: "key.fill")
                }
            }
        } footer: {
            if manager.isMonitoringActive {
                Text("Выключить можно только введя PIN-код.")
            } else {
                Text("При первом включении задашь PIN — без него мониторинг не выключить.")
            }
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
                    Text(app).foregroundStyle(.secondary).font(.subheadline)
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
            NavigationLink("История") { HistoryView() }
        }
    }
}

// MARK: - PIN Setup

struct PinSetupSheet: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var confirm = ""
    @State private var error = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.green)

                Text("Задай PIN-код")
                    .font(.title2.bold())
                Text("Без него нельзя будет выключить мониторинг")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 16) {
                    SecureField("PIN (4 цифры)", text: $pin)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($focused)
                        .onChange(of: pin) { _, v in pin = String(v.filter(\.isNumber).prefix(4)) }

                    SecureField("Повтори PIN", text: $confirm)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: confirm) { _, v in confirm = String(v.filter(\.isNumber).prefix(4)) }
                }
                .padding(.horizontal, 32)

                if !error.isEmpty {
                    Text(error).foregroundStyle(.red).font(.footnote)
                }

                Button {
                    guard pin.count == 4 else { error = "PIN должен быть 4 цифры"; return }
                    guard pin == confirm else { error = "PIN не совпадает"; return }
                    manager.setPin(pin)
                    manager.startMonitoring()
                    dismiss()
                } label: {
                    Text("Сохранить и включить")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.horizontal, 32)
                .disabled(pin.count < 4 || confirm.count < 4)

                Spacer()
            }
            .padding(.top, 48)
            .onAppear { focused = true }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}

// MARK: - PIN Entry

struct PinEntrySheet: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss
    let onResult: (Bool) -> Void

    @State private var pin = ""
    @State private var shake = false
    @State private var attempts = 0
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.orange)

                Text("Введи PIN-код")
                    .font(.title2.bold())
                Text("Для выключения мониторинга")
                    .foregroundStyle(.secondary)

                PinDotsView(count: pin.count)
                    .offset(x: shake ? -10 : 0)
                    .animation(shake ? .easeInOut(duration: 0.05).repeatCount(5, autoreverses: true) : .default, value: shake)

                // Невидимое поле для захвата клавиатуры
                SecureField("", text: $pin)
                    .keyboardType(.numberPad)
                    .focused($focused)
                    .opacity(0)
                    .frame(width: 1, height: 1)
                    .onChange(of: pin) { _, v in
                        pin = String(v.filter(\.isNumber).prefix(4))
                        if pin.count == 4 { verify() }
                    }

                NumPadView(value: $pin)

                if attempts > 0 {
                    Text("Неверный PIN (\(attempts) попытка)")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding(.top, 48)
            .onAppear { focused = true }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }

    private func verify() {
        if manager.checkPin(pin) {
            onResult(true)
            dismiss()
        } else {
            attempts += 1
            shake = true
            pin = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shake = false }
        }
    }
}

struct PinDotsView: View {
    let count: Int
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i < count ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 18, height: 18)
                    .animation(.spring(duration: 0.2), value: count)
            }
        }
    }
}

struct NumPadView: View {
    @Binding var value: String
    private let keys = ["1","2","3","4","5","6","7","8","9","","0","⌫"]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
            ForEach(keys, id: \.self) { key in
                if key == "" {
                    Color.clear.frame(height: 60)
                } else {
                    Button {
                        if key == "⌫" {
                            if !value.isEmpty { value.removeLast() }
                        } else if value.count < 4 {
                            value.append(key)
                        }
                    } label: {
                        Text(key)
                            .font(.title.bold())
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(.secondary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Shortcuts Guide

struct ShortcutsGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Настрой один раз для каждого приложения, которое хочешь ограничить:")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    steps.padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Важно").font(.headline)
                        Text("• Сними галочку «Спрашивать перед запуском»\n• Одна автоматизация = одно приложение\n• Если ControlTime уже открыт — iOS просто переключится на него")
                            .font(.subheadline).foregroundStyle(.secondary)
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
            step("1", "Открой «Быстрые команды» → «Автоматизация» → «+»")
            step("2", "Выбери «Приложение» → выбери нужный (TikTok, Instagram…)")
            step("3", "«При открытии» → «Далее» → «Новая пустая автоматизация»")
            step("4", "Нажми «+» → найди ControlTime → «Начать упражнение»")
            step("5", "Сохрани и сними галку «Спрашивать перед запуском»")

            Text("Больше никаких условий! Действие само проверяет — нужно упражнение или нет.")
                .font(.footnote)
                .foregroundStyle(.green)
                .padding(.top, 4)
        }
    }

    private func step(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n).font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(.white).frame(width: 24, height: 24)
                .background(.green).clipShape(Circle())
            Text(text).font(.subheadline)
            Spacer()
        }
    }
}
