import SwiftUI
import AppKit

// MARK: - 主视图

struct MenuBarView: View {
    @ObservedObject private var timer = TimerManager.shared
    @ObservedObject private var settings = Settings.shared

    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        ZStack {
            // 透明背景，让 NSVisualEffectView 毛玻璃透出
            Color.clear

            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    Spacer()
                    // 设置图标
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 4)

                // 内容区
                ScrollView {
                    VStack(spacing: 18) {
                        // 倒计时区域
                        VStack(spacing: 6) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 26, weight: .light))
                                .foregroundColor(.secondary)

                            Text("距离休息还有")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)

                            Text(timer.timeRemainingString)
                                .font(.system(size: 54, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.08))
                                .monospacedDigit()
                        }
                        .padding(.top, 8)

                        // 操作按钮
                        HStack(spacing: 8) {
                            Button(action: { timer.startBreakNow() }) {
                                Text("开始休息")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.7))
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)

                            ForEach([1, 5, 15], id: \.self) { min in
                                Button(action: { timer.addWorkTime(minutes: min) }) {
                                    Text("+ \(min)分")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 9)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.6))
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)

                        // 信息卡片
                        VStack(spacing: 0) {
                            infoRow(
                                icon: "bolt.fill",
                                iconColor: Color(red: 1.0, green: 0.78, blue: 0.0),
                                title: "当前专注时间",
                                value: timer.currentFocusTimeString
                            )
                            Divider().background(Color.black.opacity(0.06))
                            infoRow(
                                icon: "leaf.fill",
                                iconColor: Color(red: 0.85, green: 0.35, blue: 0.65),
                                title: "即将到来的休息",
                                value: "\(settings.breakSeconds >= 60 ? "长休息" : "短休息") · \(settings.breakSeconds >= 60 ? "\(settings.breakSeconds / 60)分" : "\(settings.breakSeconds)秒")"
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.5))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func infoRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.08, green: 0.08, blue: 0.08))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
