import SwiftUI
import FamilyControls

struct DashboardView: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @State private var isPickerPresented = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Приложения под контролем") {
                    Button {
                        isPickerPresented = true
                    } label: {
                        HStack {
                            Text("Выбрать приложения")
                            Spacer()
                            Text(selectionSummary)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Условия разблокировки") {
                    Stepper("Интервал: \(manager.intervalMinutes) мин", value: $manager.intervalMinutes, in: 1...120)
                    Stepper("\(manager.repsPerInterval) повторений", value: $manager.repsPerInterval, in: 1...100)
                    Picker("Упражнение", selection: $manager.exerciseType) {
                        ForEach(ExerciseType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section {
                    Toggle("Контроль включён", isOn: Binding(
                        get: { manager.isMonitoringActive },
                        set: { newValue in
                            if newValue {
                                manager.startMonitoring()
                            } else {
                                manager.stopMonitoring()
                            }
                        }
                    ))
                } footer: {
                    Text("Когда включено, выбранные приложения будут блокироваться каждые \(manager.intervalMinutes) минут использования, пока ты не выполнишь упражнение.")
                }

                Section {
                    NavigationLink("История") {
                        HistoryView()
                    }
                }
            }
            .navigationTitle("ControlTime")
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $manager.selection)
            .onChange(of: manager.selection) { _, _ in
                manager.persistSelection()
            }
            .onChange(of: manager.intervalMinutes) { _, _ in manager.persistSettings() }
            .onChange(of: manager.repsPerInterval) { _, _ in manager.persistSettings() }
            .onChange(of: manager.exerciseType) { _, _ in manager.persistSettings() }
        }
    }

    private var selectionSummary: String {
        let count = manager.selection.applicationTokens.count
            + manager.selection.categoryTokens.count
            + manager.selection.webDomainTokens.count
        return count == 0 ? "не выбрано" : "\(count)"
    }
}
