import SwiftUI

/// 设置面板
struct SettingsView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var timer = TimerManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // 标题
                Text("设置")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.bottom, 4)

                // 计时设置
                settingsSection(title: "计时设置", icon: "timer") {
                    VStack(alignment: .leading, spacing: 16) {
                        stepperRow(
                            title: "工作时长",
                            subtitle: "每次专注的时间",
                            value: $settings.workMinutes,
                            range: 5...60,
                            unit: "分钟"
                        )

                        Divider()

                        stepperRow(
                            title: "休息时长",
                            subtitle: "每次休息的时间",
                            value: $settings.breakSeconds,
                            range: 10...300,
                            unit: "秒"
                        )
                    }
                }

                // 提醒设置
                settingsSection(title: "提醒设置", icon: "bell") {
                    VStack(alignment: .leading, spacing: 14) {
                        toggleRow(
                            title: "提示音",
                            subtitle: "休息开始和结束时播放声音",
                            isOn: $settings.soundEnabled
                        )

                        Divider()

                        toggleRow(
                            title: "严格模式",
                            subtitle: "休息期间无法跳过，必须完成",
                            isOn: $settings.strictMode
                        )

                        Divider()

                        toggleRow(
                            title: "菜单栏显示倒计时",
                            subtitle: "在菜单栏图标旁显示剩余时间",
                            isOn: $settings.showTimerInMenuBar
                        )
                    }
                }

                // 健康提醒
                settingsSection(title: "健康提醒", icon: "heart.text.square") {
                    VStack(alignment: .leading, spacing: 14) {
                        toggleRow(
                            title: "眨眼提醒",
                            subtitle: "定时提醒眨眼，缓解眼疲劳",
                            isOn: $settings.blinkReminderEnabled
                        )

                        if settings.blinkReminderEnabled {
                            stepperRow(
                                title: "眨眼间隔",
                                subtitle: "每隔多久提醒一次眨眼",
                                value: $settings.blinkIntervalMinutes,
                                range: 1...30,
                                unit: "分钟"
                            )
                        }

                        Divider()

                        toggleRow(
                            title: "站立提醒",
                            subtitle: "定时提醒站起来活动身体",
                            isOn: $settings.standingReminderEnabled
                        )

                        if settings.standingReminderEnabled {
                            stepperRow(
                                title: "站立间隔",
                                subtitle: "每隔多久提醒一次站立",
                                value: $settings.standingIntervalMinutes,
                                range: 15...120,
                                unit: "分钟"
                            )
                        }

                        Divider()

                        toggleRow(
                            title: "喝水提醒",
                            subtitle: "定时提醒喝水，补充水分",
                            isOn: $settings.waterReminderEnabled
                        )

                        if settings.waterReminderEnabled {
                            stepperRow(
                                title: "喝水间隔",
                                subtitle: "每隔多久提醒一次喝水",
                                value: $settings.waterIntervalMinutes,
                                range: 15...120,
                                unit: "分钟"
                            )
                        }
                    }
                }

                // 通用设置
                settingsSection(title: "通用", icon: "gearshape") {
                    VStack(alignment: .leading, spacing: 14) {
                        toggleRow(
                            title: "开机自启动",
                            subtitle: "登录时自动启动 MikiReminder",
                            isOn: $settings.launchAtLogin
                        )

                        Divider()

                        toggleRow(
                            title: "空闲时暂停",
                            subtitle: "检测到电脑空闲时自动暂停计时",
                            isOn: $settings.pauseWhenIdle
                        )
                    }
                }

                // 预设方案
                settingsSection(title: "快速预设", icon: "bolt") {
                    HStack(spacing: 12) {
                        presetButton(title: "20-20-20", desc: "标准护眼") {
                            settings.workMinutes = 20
                            settings.breakSeconds = 20
                            timer.reset()
                            timer.start()
                        }
                        presetButton(title: "25-5", desc: "番茄工作法") {
                            settings.workMinutes = 25
                            settings.breakSeconds = 300
                            timer.reset()
                            timer.start()
                        }
                        presetButton(title: "50-10", desc: "深度工作") {
                            settings.workMinutes = 50
                            settings.breakSeconds = 600
                            timer.reset()
                            timer.start()
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(28)
        }
        .frame(width: 480, height: 880)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - 子视图组件

    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 4)

            content()
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
        }
    }

    private func stepperRow(title: String, subtitle: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Stepper("", value: value, in: range)
                    .labelsHidden()
                Text("\(value.wrappedValue) \(unit)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.blue)
                    .frame(width: 70, alignment: .trailing)
            }
        }
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    private func presetButton(title: String, desc: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}
