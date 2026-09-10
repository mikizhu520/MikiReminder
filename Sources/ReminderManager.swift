import Foundation
import Combine
import AppKit

/// 眨眼、站立、喝水提醒管理器
final class ReminderManager: ObservableObject {
    static let shared = ReminderManager()

    @Published private(set) var secondsSinceLastBlink: Int = 0
    @Published private(set) var secondsSinceLastStanding: Int = 0
    @Published private(set) var secondsSinceLastWater: Int = 0

    /// 眨眼提醒回调
    var onBlinkReminder: (() -> Void)?
    /// 站立提醒回调
    var onStandingReminder: (() -> Void)?
    /// 喝水提醒回调
    var onWaterReminder: (() -> Void)?

    private var timer: Timer?
    private let settings = Settings.shared
    private let timerManager = TimerManager.shared

    private init() {}

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// 重置眨眼提醒计时
    func resetBlink() {
        secondsSinceLastBlink = 0
    }

    /// 重置站立提醒计时
    func resetStanding() {
        secondsSinceLastStanding = 0
    }

    /// 重置喝水提醒计时
    func resetWater() {
        secondsSinceLastWater = 0
    }

    private func tick() {
        // 暂停或休息时不计时
        guard timerManager.phase == .working else {
            return
        }

        secondsSinceLastBlink += 1
        secondsSinceLastStanding += 1
        secondsSinceLastWater += 1

        // 眨眼提醒
        if settings.blinkReminderEnabled {
            let blinkInterval = settings.blinkIntervalMinutes * 60
            if secondsSinceLastBlink >= blinkInterval {
                secondsSinceLastBlink = 0
                DispatchQueue.main.async { [weak self] in
                    self?.onBlinkReminder?()
                }
            }
        }

        // 站立提醒
        if settings.standingReminderEnabled {
            let standingInterval = settings.standingIntervalMinutes * 60
            if secondsSinceLastStanding >= standingInterval {
                secondsSinceLastStanding = 0
                DispatchQueue.main.async { [weak self] in
                    self?.onStandingReminder?()
                }
            }
        }

        // 喝水提醒
        if settings.waterReminderEnabled {
            let waterInterval = settings.waterIntervalMinutes * 60
            if secondsSinceLastWater >= waterInterval {
                secondsSinceLastWater = 0
                DispatchQueue.main.async { [weak self] in
                    self?.onWaterReminder?()
                }
            }
        }
    }
}
