import Foundation
import Combine
import AppKit
import UserNotifications

enum TimerPhase {
    case working
    case onBreak
    case paused
}

enum BreakType {
    case scheduled   // 定时触发的休息
    case natural     // 用户手动触发的休息
}

/// 核心计时器，管理工作/休息周期
final class TimerManager: ObservableObject {
    static let shared = TimerManager()

    @Published private(set) var phase: TimerPhase = .working
    @Published private(set) var timeRemaining: TimeInterval
    @Published private(set) var cyclesCompleted: Int = 0
    @Published private(set) var currentFocusTime: TimeInterval = 0

    var onBreakStart: (() -> Void)?
    var onBreakEnd: (() -> Void)?

    private var timer: Timer?
    private var settings = Settings.shared
    private var lastTick: Date?
    private var currentBreakType: BreakType = .scheduled

    private init() {
        self.timeRemaining = Settings.shared.workDuration
    }

    // MARK: - 控制

    func start() {
        if phase == .paused {
            phase = .working
        }
        // 已经在运行则不重复启动
        guard timer == nil else { return }
        lastTick = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func pause() {
        guard phase == .working else { return }
        phase = .paused
        timer?.invalidate()
        timer = nil
        lastTick = nil
    }

    func resume() {
        guard phase == .paused else { return }
        start()
    }

    func skipBreak() {
        guard phase == .onBreak else { return }
        endBreak(completed: false)
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        phase = .working
        timeRemaining = settings.workDuration
        cyclesCompleted = 0
        currentFocusTime = 0
        lastTick = nil
    }

    /// 延时休息：给当前工作时段增加时间
    func addWorkTime(minutes: Int) {
        guard phase == .working || phase == .paused else { return }
        timeRemaining += TimeInterval(minutes * 60)
        if phase == .paused {
            // 保持暂停状态，不自动开始
        }
    }

    /// 立即开始一次休息（手动触发 = 自然休息）
    func startBreakNow() {
        guard phase == .working || phase == .paused else { return }
        currentBreakType = .natural
        timer?.invalidate()
        timer = nil
        beginBreak()
    }

    // MARK: - 计时逻辑

    private func tick() {
        guard let last = lastTick else {
            lastTick = Date()
            return
        }
        let now = Date()
        let elapsed = now.timeIntervalSince(last)
        lastTick = now

        switch phase {
        case .working:
            timeRemaining -= elapsed
            currentFocusTime += elapsed
            if timeRemaining <= 0 {
                currentBreakType = .scheduled
                beginBreak()
            }
        case .onBreak:
            timeRemaining -= elapsed
            if timeRemaining <= 0 {
                endBreak(completed: true)
            }
        case .paused:
            break
        }
    }

    private func beginBreak() {
        phase = .onBreak
        timeRemaining = settings.breakDuration
        lastTick = Date()
        cyclesCompleted += 1

        if settings.soundEnabled {
            NSSound(named: "Glass")?.play()
        }

        // 发送系统通知
        sendNotification(title: "休息时间到", body: "看看 20 英尺（约 6 米）外的物体，放松眼睛")

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)

        onBreakStart?()
    }

    private func endBreak(completed: Bool) {
        phase = .working
        timeRemaining = settings.workDuration
        currentFocusTime = 0
        lastTick = Date()
        currentBreakType = .scheduled

        if settings.soundEnabled {
            NSSound(named: "Ping")?.play()
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)

        onBreakEnd?()
    }

    // MARK: - 通知

    /// 请求通知权限（在应用启动时调用）
    static func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            if self.settings.soundEnabled {
                content.sound = .default
            }

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            center.add(request)
        }
    }

    // MARK: - 显示用格式化

    var timeRemainingString: String {
        let total = Int(ceil(timeRemaining))
        let minutes = total / 60
        let seconds = total % 60
        // 统一显示 MM:SS 格式
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 当前专注时长的友好显示
    var currentFocusTimeString: String {
        let minutes = Int(currentFocusTime / 60)
        if minutes < 60 {
            return "\(minutes)分"
        }
        let hours = minutes / 60
        let remainMin = minutes % 60
        return remainMin > 0 ? "\(hours)时\(remainMin)分" : "\(hours)时"
    }

    var progress: Double {
        switch phase {
        case .working:
            let total = settings.workDuration
            return total > 0 ? 1 - (timeRemaining / total) : 0
        case .onBreak:
            let total = settings.breakDuration
            return total > 0 ? 1 - (timeRemaining / total) : 0
        case .paused:
            return 0
        }
    }

    var statusText: String {
        switch phase {
        case .working: return "专注中"
        case .onBreak: return "休息中"
        case .paused: return "已暂停"
        }
    }
}
