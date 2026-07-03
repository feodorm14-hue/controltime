# ControlTime

Личное iOS-приложение в духе PushUp Time: выбираешь приложения, которые
"съедают" время, и когда лимит исчерпан — они блокируются, пока не выполнишь
упражнение (например, 15 минут экранного времени = 15 приседаний).

## Как это работает

iOS не позволяет сторонним приложениям читать активность других приложений
или блокировать их напрямую — это делается только через официальный
**Screen Time API** (`FamilyControls` / `DeviceActivity` / `ManagedSettings`).
Архитектура:

1. **ControlTime** (основное приложение) — запрашивает авторизацию,
   даёт выбрать приложения через `FamilyActivityPicker`, задаёт правило
   "N минут = M повторений" и планирует мониторинг через `DeviceActivityCenter`.
2. **ControlTimeMonitor** (`DeviceActivityMonitor` extension) — срабатывает,
   когда набежал заданный порог минут использования выбранных приложений,
   и накладывает блокировку (`ManagedSettingsStore`).
3. **ControlTimeShieldConfiguration** — рисует экран блокировки
   ("Сделай 15 приседаний, чтобы продолжить").
4. **ControlTimeShieldAction** — обрабатывает нажатие кнопки на экране
   блокировки и открывает основное приложение на экране упражнения.
5. Экран упражнения показывает превью фронтальной камеры. Apple Vision
   (`VNDetectHumanBodyPoseRequest`) детектирует ключевые точки тела в каждом
   кадре, вычисляет угол в колене (приседания), локте (отжимания) или плече
   (джампинг-джек) и считает повторение при переходе из фазы DOWN обратно в UP.
   Телефон ставится на стол/стул перед пользователем. Плюс кнопка "+1 вручную"
   на случай плохого освещения или нестандартного угла. После выполнения нормы
   блокировка снимается и открывается новое временное окно.

Все четыре таргета обмениваются данными через App Group (`UserDefaults`),
без сервера — всё локально на устройстве.

## Требования

- macOS + Xcode 15+.
- Бесплатного или платного Apple Developer аккаунта достаточно — авторизация
  `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
  предназначена именно для приложений личного самоконтроля и не требует
  отдельного одобрения Apple (в отличие от родительского контроля `.child`).
- **Реальный iPhone.** Screen Time API не работает в симуляторе.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) для генерации `.xcodeproj`
  из `project.yml` (сам `.xcodeproj` не хранится в репозитории):
  ```bash
  brew install xcodegen
  ```

## Сборка

```bash
cd controltime
xcodegen generate
open ControlTime.xcodeproj
```

В Xcode:

1. Для каждого из 4 таргетов (ControlTime, ControlTimeMonitor,
   ControlTimeShieldConfiguration, ControlTimeShieldAction) во вкладке
   *Signing & Capabilities* выбери свою команду (Team) — Automatic signing
   создаст нужные bundle ID и профили сам.
2. Проверь, что App Group `group.com.controltime.app` создался у всех
   таргетов (обычно Xcode делает это автоматически при первой сборке
   благодаря entitlements в `project.yml`; если нет — добавь его вручную
   в Signing & Capabilities → + Capability → App Groups).
3. Подключи iPhone, выбери его как Destination, Run.
4. При первом запуске разреши доступ к экранному времени и датчикам
   движения (алерты появятся сами).

## Известные ограничения MVP

- **Body Pose** работает только при хорошем освещении и когда тело видно
  в кадр целиком. Пороги углов (120°/155° для приседаний, 95°/140° для
  отжиманий) подобраны усреднённо — при необходимости подстрой константы
  `squatDownThreshold` / `squatUpThreshold` в `PoseExerciseCounter.swift`.
  Кнопка "Засчитать вручную" — страховка на случай плохого захвата позы.
- Открытие приложения из `ShieldActionExtension` через
  `extensionContext?.open(...)` — распространённый, но не задокументированный
  Apple приём. На случай, если система его заблокирует, основное приложение
  дополнительно само проверяет флаг активной блокировки при каждом переходе
  в foreground (`scenePhase == .active`) и открывает экран упражнения
  независимо от способа возврата в приложение.
- Правило одно на всё приложение (один интервал, одна норма повторений,
  один тип упражнения) — осознанно упрощено для личного использования.
- Значок приложения (`AppIcon`) и часть плейсхолдеров — пустые, добавь
  свою иконку в `Sources/ControlTime/Resources/Assets.xcassets/AppIcon.appiconset`.

## Структура проекта

```
project.yml                          # описание проекта для XcodeGen
Sources/
  Shared/                            # общие константы (App Group, ключи, типы упражнений)
  ControlTime/                       # основное приложение (SwiftUI)
    App/                             # точка входа
    Views/                           # экраны: онбординг, дашборд, упражнение, история
    Managers/                        # ScreenTimeManager, MotionExerciseCounter
    Models/                          # ExerciseSession, HistoryStore
    Resources/                       # Info.plist, Assets.xcassets
  ControlTimeMonitor/                # DeviceActivityMonitor extension
  ControlTimeShieldConfiguration/    # экран блокировки (UI)
  ControlTimeShieldAction/           # обработка кнопок экрана блокировки
```
