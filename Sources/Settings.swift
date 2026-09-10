import Foundation
import Combine
import AppKit

/// 外观模式
enum AppearanceMode: String, CaseIterable {
    case system = "跟随系统"
    case light = "浅色"
    case dark = "深色"

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

/// 应用设置，基于 UserDefaults 持久化
final class Settings: ObservableObject {
    static let shared = Settings()

    @Published var workMinutes: Int {
        didSet { UserDefaults.standard.set(workMinutes, forKey: "workMinutes") }
    }
    @Published var breakSeconds: Int {
        didSet { UserDefaults.standard.set(breakSeconds, forKey: "breakSeconds") }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    @Published var strictMode: Bool {
        didSet { UserDefaults.standard.set(strictMode, forKey: "strictMode") }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }
    @Published var pauseWhenIdle: Bool {
        didSet { UserDefaults.standard.set(pauseWhenIdle, forKey: "pauseWhenIdle") }
    }
    @Published var showTimerInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showTimerInMenuBar, forKey: "showTimerInMenuBar") }
    }
    @Published var blinkReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(blinkReminderEnabled, forKey: "blinkReminderEnabled") }
    }
    @Published var blinkIntervalMinutes: Int {
        didSet { UserDefaults.standard.set(blinkIntervalMinutes, forKey: "blinkIntervalMinutes") }
    }
    @Published var standingReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(standingReminderEnabled, forKey: "standingReminderEnabled") }
    }
    @Published var standingIntervalMinutes: Int {
        didSet { UserDefaults.standard.set(standingIntervalMinutes, forKey: "standingIntervalMinutes") }
    }
    @Published var waterReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(waterReminderEnabled, forKey: "waterReminderEnabled") }
    }
    @Published var waterIntervalMinutes: Int {
        didSet { UserDefaults.standard.set(waterIntervalMinutes, forKey: "waterIntervalMinutes") }
    }
    @Published var appearanceMode: String {
        didSet {
            UserDefaults.standard.set(appearanceMode, forKey: "appearanceMode")
            applyAppearance()
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        self.workMinutes = defaults.object(forKey: "workMinutes") as? Int ?? 20
        self.breakSeconds = defaults.object(forKey: "breakSeconds") as? Int ?? 20
        self.soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        self.strictMode = defaults.object(forKey: "strictMode") as? Bool ?? false
        self.launchAtLogin = defaults.object(forKey: "launchAtLogin") as? Bool ?? false
        self.pauseWhenIdle = defaults.object(forKey: "pauseWhenIdle") as? Bool ?? true
        self.showTimerInMenuBar = defaults.object(forKey: "showTimerInMenuBar") as? Bool ?? true
        self.blinkReminderEnabled = defaults.object(forKey: "blinkReminderEnabled") as? Bool ?? true
        self.blinkIntervalMinutes = defaults.object(forKey: "blinkIntervalMinutes") as? Int ?? 10
        self.standingReminderEnabled = defaults.object(forKey: "standingReminderEnabled") as? Bool ?? true
        self.standingIntervalMinutes = defaults.object(forKey: "standingIntervalMinutes") as? Int ?? 45
        self.waterReminderEnabled = defaults.object(forKey: "waterReminderEnabled") as? Bool ?? true
        self.waterIntervalMinutes = defaults.object(forKey: "waterIntervalMinutes") as? Int ?? 30
        self.appearanceMode = defaults.object(forKey: "appearanceMode") as? String ?? "system"
    }

    /// 当前外观模式枚举
    var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

    /// 应用外观设置
    func applyAppearance() {
        DispatchQueue.main.async {
            NSApp.appearance = self.appearance.nsAppearance
        }
    }

    var workDuration: TimeInterval { TimeInterval(workMinutes * 60) }
    var breakDuration: TimeInterval { TimeInterval(breakSeconds) }

    /// 通过 LaunchAgent 实现开机启动
    private func updateLaunchAtLogin() {
        let appName = "MikiReminder"
        let label = "com.mikireminder.helper"
        let plistPath = ("~/Library/LaunchAgents/\(label).plist" as NSString).expandingTildeInPath

        if launchAtLogin {
            let appPath = "/Applications/\(appName).app"
            let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>\(label)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>/usr/bin/open</string>
                    <string>\(appPath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
            </dict>
            </plist>
            """
            try? FileManager.default.createDirectory(
                atPath: ("~/Library/LaunchAgents" as NSString).expandingTildeInPath,
                withIntermediateDirectories: true
            )
            try? plist.write(toFile: plistPath, atomically: true, encoding: .utf8)
        } else {
            try? FileManager.default.removeItem(atPath: plistPath)
        }
    }
}
