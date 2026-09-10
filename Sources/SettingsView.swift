import SwiftUI

/// 设置面板（液态玻璃风格 + 左侧 Tab 切换）
struct SettingsView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var timer = TimerManager.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: SettingsTab = .timer

    enum SettingsTab: String, CaseIterable {
        case timer = "计时"
        case reminder = "提醒"
        case health = "健康"

        var icon: String {
            switch self {
            case .timer: return "timer"
            case .reminder: return "bell.fill"
            case .health: return "heart.fill"
            }
        }
    }

    // MARK: - 自适应颜色

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.9)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.5)
    }

    private var tabUnselectedText: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.75)
    }

    private var sidebarBg: Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04)
    }

    private var cardBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
    }

    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    var body: some View {
        ZStack {
            // 背景：深色模式不透明，浅色模式毛玻璃
            if colorScheme == .dark {
                Color(NSColor.windowBackgroundColor)
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }

            HStack(spacing: 0) {
            // 左侧 Tab 栏
            VStack(spacing: 2) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 20)
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTab == tab ? Color.blue.opacity(0.18) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedTab == tab ? Color.blue.opacity(0.35) : Color.clear, lineWidth: 0.5)
                        )
                        .foregroundColor(selectedTab == tab ? .blue : tabUnselectedText)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .frame(width: 120)
            .padding(.top, 16)
            .padding(.horizontal, 10)
            .padding(.bottom, 16)
            .background(sidebarBg)

            // 右侧内容区
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    switch selectedTab {
                    case .timer:
                        timerSettings
                    case .reminder:
                        reminderSettings
                    case .health:
                        healthSettings
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        }
        .frame(width: 580, height: 540)
    }

    // MARK: - 计时设置

    private var timerSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("计时设置")

            glassCard {
                VStack(alignment: .leading, spacing: 0) {
                    stepperRow(
                        title: "工作时长",
                        subtitle: "每次专注的时间",
                        value: $settings.workMinutes,
                        range: 5...60,
                        unit: "分钟"
                    )
                    glassDivider
                    stepperRow(
                        title: "休息时长",
                        subtitle: "每次休息的时间",
                        value: $settings.breakSeconds,
                        range: 10...300,
                        unit: "秒"
                    )
                }
            }

            sectionTitle("快速预设", small: true)

            HStack(spacing: 10) {
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
    }

    // MARK: - 提醒设置

    private var reminderSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("提醒设置")

            glassCard {
                VStack(alignment: .leading, spacing: 0) {
                    toggleRow(
                        title: "提示音",
                        subtitle: "休息开始和结束时播放声音",
                        isOn: $settings.soundEnabled
                    )
                    glassDivider
                    toggleRow(
                        title: "严格模式",
                        subtitle: "休息期间无法跳过，必须完成",
                        isOn: $settings.strictMode
                    )
                    glassDivider
                    toggleRow(
                        title: "菜单栏显示倒计时",
                        subtitle: "在菜单栏图标旁显示剩余时间",
                        isOn: $settings.showTimerInMenuBar
                    )
                }
            }

            sectionTitle("通用", small: true)

            glassCard {
                VStack(alignment: .leading, spacing: 0) {
                    toggleRow(
                        title: "开机自启动",
                        subtitle: "登录时自动启动 MikiReminder",
                        isOn: $settings.launchAtLogin
                    )
                    glassDivider
                    toggleRow(
                        title: "空闲时暂停",
                        subtitle: "检测到电脑空闲时自动暂停计时",
                        isOn: $settings.pauseWhenIdle
                    )
                    glassDivider
                    appearanceRow
                }
            }
        }
    }

    // MARK: - 健康提醒设置

    private var healthSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("健康提醒")

            glassCard {
                VStack(alignment: .leading, spacing: 0) {
                    toggleRow(
                        title: "眨眼提醒",
                        subtitle: "定时提醒眨眼，缓解眼疲劳",
                        isOn: $settings.blinkReminderEnabled
                    )
                    if settings.blinkReminderEnabled {
                        glassDivider
                        stepperRow(
                            title: "眨眼间隔",
                            subtitle: "每隔多久提醒一次",
                            value: $settings.blinkIntervalMinutes,
                            range: 1...30,
                            unit: "分钟"
                        )
                    }

                    glassDivider

                    toggleRow(
                        title: "站立提醒",
                        subtitle: "定时提醒站起来活动身体",
                        isOn: $settings.standingReminderEnabled
                    )
                    if settings.standingReminderEnabled {
                        glassDivider
                        stepperRow(
                            title: "站立间隔",
                            subtitle: "每隔多久提醒一次",
                            value: $settings.standingIntervalMinutes,
                            range: 15...120,
                            unit: "分钟"
                        )
                    }

                    glassDivider

                    toggleRow(
                        title: "喝水提醒",
                        subtitle: "定时提醒喝水，补充水分",
                        isOn: $settings.waterReminderEnabled
                    )
                    if settings.waterReminderEnabled {
                        glassDivider
                        stepperRow(
                            title: "喝水间隔",
                            subtitle: "每隔多久提醒一次",
                            value: $settings.waterIntervalMinutes,
                            range: 15...120,
                            unit: "分钟"
                        )
                    }
                }
            }
        }
    }

    // MARK: - 组件

    private func sectionTitle(_ text: String, small: Bool = false) -> some View {
        Text(text)
            .font(.system(size: small ? 13 : 17, weight: .semibold))
            .foregroundColor(small ? secondaryText : primaryText)
            .padding(.bottom, small ? -8 : 0)
    }

    private var glassDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    private func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(cardBorder, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func stepperRow(title: String, subtitle: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(primaryText)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }
            Spacer()
            HStack(spacing: 8) {
                Stepper("", value: value, in: range)
                    .labelsHidden()
                Text("\(value.wrappedValue)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
                    .frame(minWidth: 28, alignment: .trailing)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }
        }
        .padding(.vertical, 12)
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.wrappedValue.toggle()
            }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(primaryText)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(secondaryText)
                }
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .allowsHitTesting(false)
                    .scaleEffect(0.85)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 12)
    }

    private var appearanceRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("外观")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(primaryText)
                Text("选择应用显示模式")
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
            }
            Spacer()
            Picker("", selection: $settings.appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                    Text(mode.rawValue).tag(mode.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
        .padding(.vertical, 12)
    }

    private func presetButton(title: String, desc: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(primaryText)
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundColor(secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.25), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}
