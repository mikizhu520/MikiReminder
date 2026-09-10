import SwiftUI
import AppKit

/// 提醒类型
enum ReminderType {
    case blink
    case standing
    case water
}

/// 通用提醒卡片视图
struct ReminderView: View {
    let type: ReminderType
    var onDismiss: () -> Void

    @State private var animate = false
    @State private var opacity = 0.0

    private var title: String {
        switch type {
        case .blink: return "眨眨眼"
        case .standing: return "站起来活动一下"
        case .water: return "该喝水啦"
        }
    }

    private var subtitle: String {
        switch type {
        case .blink: return "让眼睛放松一下，看看远处"
        case .standing: return "伸展身体，促进血液循环"
        case .water: return "喝口水，补充水分，保持健康"
        }
    }

    private var iconName: String {
        switch type {
        case .blink: return "eye"
        case .standing: return "figure.stand"
        case .water: return "cup.and.saucer.fill"
        }
    }

    private var iconColor: Color {
        switch type {
        case .blink: return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .standing: return Color(red: 0.9, green: 0.5, blue: 0.2)
        case .water: return Color(red: 0.1, green: 0.6, blue: 0.85)
        }
    }

    var body: some View {
        ZStack {
            // 点击背景关闭
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }

            // 提醒卡片
            VStack(spacing: 16) {
                // 动画图标
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: iconName)
                        .font(.system(size: 38, weight: .light))
                        .foregroundColor(iconColor)
                        .scaleEffect(y: animate ? (type == .blink ? 0.1 : 1.0) : 1.0)
                        .scaleEffect(animate ? (type == .standing ? 1.1 : 1.0) : 1.0)
                        .offset(y: animate ? ((type == .standing || type == .water) ? -6 : 0) : 0)
                        .rotationEffect(.degrees(animate ? (type == .water ? -8 : 0) : 0))
                }

                // 文字
                VStack(spacing: 5) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 8)
            .opacity(opacity)
            .scaleEffect(opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // 入场动画
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1.0
            }

            // 循环动画
            switch type {
            case .blink:
                // 眨眼动画：每 2 秒眨一次
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        animate = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            animate = false
                        }
                    }
                }
            case .standing:
                // 站立动画：上下浮动
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animate = true
                }
            case .water:
                // 喝水动画：杯子轻轻倾斜浮动
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }

            // 5 秒后自动消失
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onDismiss()
                }
            }
        }
    }
}
