import SwiftUI
import AppKit

/// 全屏休息倒计时界面（深色毛玻璃 + 暖白文字，复刻 LookAway 风格）
struct BreakView: View {
    @ObservedObject private var timer = TimerManager.shared
    @ObservedObject private var settings = Settings.shared
    var onSkip: () -> Void

    @State private var currentTime = ""
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// 休息时长 >= 60秒 视为长休息
    private var isLongBreak: Bool {
        settings.breakDuration >= 60
    }

    private var breakLabel: String {
        isLongBreak ? "长休息" : "短休息"
    }

    private var titleText: String {
        isLongBreak ? "该好好充个电了" : "休息一下"
    }

    private var subtitleText: String {
        isLongBreak
            ? "站起来，走一走，换个视角，等我们回来再继续"
            : "看向 20 英尺（约 6 米）外的物体，让眼睛放松"
    }

    /// 暖白色（奶油色）
    private var warmWhite: Color {
        Color(red: 0.96, green: 0.93, blue: 0.86)
    }

    var body: some View {
        ZStack {
            // 额外深色叠加，让壁纸更暗更舒适
            Color.black.opacity(0.35)

            VStack(spacing: 0) {
                // 顶部时钟
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 13, weight: .regular))
                    Text(currentTime)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 56)

                Spacer()

                // 中心内容
                VStack(spacing: 18) {
                    // 休息类型标签
                    Text(breakLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                        )

                    // 主标题
                    Text(titleText)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(warmWhite)

                    // 副标题
                    Text(subtitleText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    // 分割线
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 44, height: 1)

                    // 倒计时
                    Text(timer.timeRemainingString)
                        .font(.system(size: 52, weight: .medium, design: .rounded))
                        .foregroundColor(warmWhite)
                        .monospacedDigit()
                }

                Spacer()

                // 底部按钮区域
                VStack(spacing: 14) {
                    HStack(spacing: 16) {
                        // 跳过休息
                        Button(action: onSkip) {
                            HStack(spacing: 7) {
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 13))
                                Text("跳过休息")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // 锁定屏幕
                        Button(action: lockScreen) {
                            HStack(spacing: 7) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 13))
                                Text("锁定屏幕")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Esc 提示
                    Text("按 Esc 两次即可跳过休息")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.bottom, 56)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            updateClock()
        }
        .onReceive(clockTimer) { _ in
            updateClock()
        }
    }

    private func updateClock() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        currentTime = formatter.string(from: Date())
    }

    private func lockScreen() {
        // 让显示器休眠（等同于锁屏效果）
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]
        try? task.run()
    }
}
