import AppKit
import SwiftUI
import Combine

/// 应用代理：管理菜单栏、窗口和生命周期
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var breakWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var reminderWindow: NSWindow?

    private var timer = TimerManager.shared
    private var settings = Settings.shared
    private var reminderManager = ReminderManager.shared
    private var cancellables = Set<AnyCancellable>()

    // Esc 双击跳过休息
    private var escPressCount = 0
    private var escResetTimer: Timer?
    private var localEventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 不显示 Dock 图标，纯菜单栏应用
        NSApp.setActivationPolicy(.accessory)

        // 请求通知权限
        TimerManager.requestNotificationAuthorization()

        setupStatusItem()
        setupPopover()
        setupTimerCallbacks()
        setupMenuBarTimerUpdate()
        setupReminderCallbacks()

        // 启动计时
        timer.start()
        // 启动眨眼/站立提醒
        reminderManager.start()
    }

    // MARK: - 菜单栏

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "MikiReminder")
            button.image?.isTemplate = true
            button.action = #selector(handleStatusItemClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func handleStatusItemClick(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else {
            togglePopover(sender)
            return
        }

        if event.type == .rightMouseUp {
            showRightClickMenu()
        } else {
            togglePopover(sender)
        }
    }

    /// 右键菜单
    private func showRightClickMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // 顶部信息
        let breakType = settings.breakSeconds >= 60 ? "长休息" : "短休息"
        let breakDuration = settings.breakSeconds >= 60 ? "\(settings.breakSeconds / 60)分" : "\(settings.breakSeconds)秒"
        let breakInfo = NSMenuItem(
            title: "\(breakType) · \(breakDuration) · \(timer.timeRemainingString)后",
            action: nil,
            keyEquivalent: ""
        )
        breakInfo.isEnabled = false
        menu.addItem(breakInfo)
        menu.addItem(.separator())

        // 立即开始休息
        menu.addItem(withTitle: "立即开始本次休息", action: #selector(menuStartBreak), keyEquivalent: "")
        // 推迟休息子菜单
        let postponeMenu = NSMenu()
        postponeMenu.addItem(withTitle: "+1 分钟", action: #selector(menuPostpone1), keyEquivalent: "")
        postponeMenu.addItem(withTitle: "+5 分钟", action: #selector(menuPostpone5), keyEquivalent: "")
        postponeMenu.addItem(withTitle: "+15 分钟", action: #selector(menuPostpone15), keyEquivalent: "")
        let postponeItem = NSMenuItem(title: "推迟休息", action: nil, keyEquivalent: "")
        postponeItem.submenu = postponeMenu
        menu.addItem(postponeItem)

        // 暂停/继续
        if timer.phase == .working {
            menu.addItem(withTitle: "暂停计时", action: #selector(menuPause), keyEquivalent: "")
        } else if timer.phase == .paused {
            menu.addItem(withTitle: "继续计时", action: #selector(menuResume), keyEquivalent: "")
        }

        menu.addItem(.separator())

        // 停止 MikiReminder
        let stopItem = NSMenuItem(title: "停止 MikiReminder", action: #selector(menuStop), keyEquivalent: "t")
        stopItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(stopItem)

        menu.addItem(.separator())

        // 设置
        let settingsItem = NSMenuItem(title: "设置...", action: #selector(menuOpenSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = [.command]
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        // 关于
        menu.addItem(withTitle: "关于 MikiReminder", action: #selector(menuAbout), keyEquivalent: "")
        // 退出
        let quitItem = NSMenuItem(title: "退出", action: #selector(menuQuit), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        menu.addItem(quitItem)

        if let button = statusItem.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
        }
    }

    // MARK: - 右键菜单动作

    @objc private func menuStartBreak() { timer.startBreakNow() }
    @objc private func menuPostpone1() { timer.addWorkTime(minutes: 1) }
    @objc private func menuPostpone5() { timer.addWorkTime(minutes: 5) }
    @objc private func menuPostpone15() { timer.addWorkTime(minutes: 15) }
    @objc private func menuPause() { timer.pause() }
    @objc private func menuResume() { timer.start() }
    @objc private func menuStop() { timer.reset() }
    @objc private func menuOpenSettings() { openSettings() }
    @objc private func menuAbout() { showAbout() }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "MikiReminder"
        alert.informativeText = "版本 1.0.0\n\n一款 macOS 护眼休息提醒应用\n遵循 20-20-20 护眼法则"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    // MARK: - 弹出面板

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 340, height: 380)

        let contentView = MenuBarView(
            onOpenSettings: { [weak self] in
                self?.popover.performClose(nil)
                self?.openSettings()
            },
            onQuit: { [weak self] in
                self?.quitApp()
            }
        )

        let hostingController = NSHostingController(rootView: contentView)

        // 毛玻璃背景
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .popover
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 14
        visualEffect.layer?.masksToBounds = true

        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        hostingController.view.addSubview(visualEffect, positioned: .below, relativeTo: hostingController.view.subviews.first)
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffect.topAnchor.constraint(equalTo: hostingController.view.topAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor),
            visualEffect.leadingAnchor.constraint(equalTo: hostingController.view.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: hostingController.view.trailingAnchor),
        ])

        popover.contentViewController = hostingController
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    // MARK: - 菜单栏倒计时更新

    private func setupMenuBarTimerUpdate() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMenuBarTitle()
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarTitle() {
        guard settings.showTimerInMenuBar,
              let button = statusItem.button else { return }

        if timer.phase == .working || timer.phase == .paused {
            // 只显示分钟，如 "20分"
            let minutes = max(1, Int(ceil(timer.timeRemaining / 60)))
            button.title = " \(minutes)分"
        } else if timer.phase == .onBreak {
            // 休息时显示秒数
            let seconds = max(1, Int(ceil(timer.timeRemaining)))
            button.title = " \(seconds)秒"
        }
    }

    // MARK: - 休息全屏窗口

    private func setupTimerCallbacks() {
        timer.onBreakStart = { [weak self] in
            DispatchQueue.main.async {
                self?.showBreakWindow()
            }
        }
        timer.onBreakEnd = { [weak self] in
            DispatchQueue.main.async {
                self?.hideBreakWindow()
            }
        }
    }

    // MARK: - 眨眼/站立提醒

    private func setupReminderCallbacks() {
        reminderManager.onBlinkReminder = { [weak self] in
            DispatchQueue.main.async {
                self?.showReminder(type: .blink)
            }
        }
        reminderManager.onStandingReminder = { [weak self] in
            DispatchQueue.main.async {
                self?.showReminder(type: .standing)
            }
        }
        reminderManager.onWaterReminder = { [weak self] in
            DispatchQueue.main.async {
                self?.showReminder(type: .water)
            }
        }
    }

    private func showReminder(type: ReminderType) {
        // 休息时不显示提醒
        guard timer.phase != .onBreak else { return }
        // 已有提醒窗口时不重复显示
        guard reminderWindow == nil else { return }

        guard let screen = NSScreen.screens.first else { return }
        let screenFrame = screen.frame
        let windowSize = NSSize(width: 360, height: 260)
        let windowRect = NSRect(
            x: (screenFrame.width - windowSize.width) / 2,
            y: (screenFrame.height - windowSize.height) / 2,
            width: windowSize.width,
            height: windowSize.height
        )

        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.setFrame(windowRect, display: true)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false

        let reminderView = ReminderView(type: type) { [weak self] in
            self?.hideReminder()
        }
        let hostingView = NSHostingView(rootView: reminderView)
        hostingView.frame = windowRect
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        reminderWindow = window
    }

    private func hideReminder() {
        reminderWindow?.orderOut(nil)
        reminderWindow = nil
    }

    private func showBreakWindow() {
        hideBreakWindow()

        // 使用主屏幕（origin 为 0,0），避免多屏时坐标偏移
        guard let screen = NSScreen.screens.first else { return }
        let frame = screen.frame

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.setFrame(frame, display: true)
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false

        // 深色毛玻璃背景层（模糊+暗化壁纸）
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .popover
        visualEffect.appearance = NSAppearance(named: .darkAqua)
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.frame = frame
        visualEffect.autoresizingMask = [.width, .height]
        window.contentView = visualEffect

        // SwiftUI 内容层
        let breakView = BreakView { [weak self] in
            self?.timer.skipBreak()
        }
        let hostingView = NSHostingView(rootView: breakView)
        hostingView.frame = frame
        hostingView.autoresizingMask = [.width, .height]
        visualEffect.addSubview(hostingView)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        breakWindow = window

        // 监听 Esc 双击跳过休息
        escPressCount = 0
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if event.keyCode == 53 { // Esc
                self.escPressCount += 1
                if self.escPressCount >= 2 {
                    self.timer.skipBreak()
                    self.escPressCount = 0
                }
                self.escResetTimer?.invalidate()
                self.escResetTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                    self.escPressCount = 0
                }
                return nil
            }
            return event
        }
    }

    private func hideBreakWindow() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        escResetTimer?.invalidate()
        escResetTimer = nil
        escPressCount = 0
        breakWindow?.orderOut(nil)
        breakWindow = nil
    }

    // MARK: - 设置窗口

    private func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 880),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "设置"
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView())
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    // MARK: - 退出

    private func quitApp() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer.pause()
    }
}
