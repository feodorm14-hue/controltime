import SwiftUI

struct AppPickerView: View {
    @Binding var selectedApps: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var customName = ""

    private let suggestions: [(name: String, icon: String)] = [
        ("TikTok", "video.fill"),
        ("Instagram", "camera.fill"),
        ("YouTube", "play.rectangle.fill"),
        ("Twitter / X", "bird.fill"),
        ("VK", "person.2.fill"),
        ("Telegram", "paperplane.fill"),
        ("ВКонтакте", "person.2.fill"),
        ("Facebook", "hand.thumbsup.fill"),
        ("Snapchat", "camera.aperture"),
        ("Reddit", "bubble.left.and.bubble.right.fill"),
        ("Twitch", "gamecontroller.fill"),
        ("Pinterest", "photo.fill"),
        ("LinkedIn", "briefcase.fill"),
        ("Discord", "waveform.badge.mic"),
        ("BeReal", "circle.square"),
        ("Likee", "star.fill"),
        ("Яндекс Дзен", "newspaper.fill"),
        ("2048", "square.grid.2x2.fill"),
        ("Subway Surfers", "figure.run"),
        ("Candy Crush", "suit.heart.fill"),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Популярные приложения") {
                    ForEach(suggestions, id: \.name) { app in
                        let selected = selectedApps.contains(app.name)
                        Button {
                            if selected {
                                selectedApps.removeAll { $0 == app.name }
                            } else {
                                selectedApps.append(app.name)
                            }
                        } label: {
                            HStack {
                                Image(systemName: app.icon)
                                    .frame(width: 28)
                                    .foregroundStyle(.secondary)
                                Text(app.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.green)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        TextField("Другое приложение…", text: $customName)
                        Button {
                            let name = customName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty, !selectedApps.contains(name) else { return }
                            selectedApps.append(name)
                            customName = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Добавить вручную")
                } footer: {
                    Text("Введи точное название, как оно отображается на экране телефона.")
                }

                if !selectedApps.isEmpty {
                    Section("Выбрано (\(selectedApps.count))") {
                        ForEach(selectedApps, id: \.self) { app in
                            HStack {
                                Image(systemName: "app.badge.checkmark")
                                    .foregroundStyle(.green)
                                Text(app)
                            }
                        }
                        .onDelete { indices in
                            selectedApps.remove(atOffsets: indices)
                        }
                    }
                }
            }
            .navigationTitle("Приложения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
