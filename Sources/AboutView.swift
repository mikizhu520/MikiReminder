import SwiftUI
import AppKit

struct AboutView: View {
    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(spacing: 0) {
            // 图标和应用名
            VStack(spacing: 12) {
                if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png"),
                   let image = NSImage(contentsOfFile: iconPath) {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 72, height: 72)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                } else {
                    Image(systemName: "eye.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                }

                VStack(spacing: 4) {
                    Text("MikiReminder")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("版本 1.0.0")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            // 分割线
            Divider()
                .opacity(isDark ? 0.3 : 0.1)

            // 信息区
            VStack(alignment: .leading, spacing: 14) {
                infoRow(icon: "person.fill", title: "开发者", value: "Miki Zhu")
                infoRow(icon: "envelope.fill", title: "邮箱", value: "750856902@qq.com", link: "mailto:750856902@qq.com")
                infoRow(icon: "chevron.left.forwardslash.chevron.right", title: "GitHub", value: "github.com/mikizhu520/MikiReminder", link: "https://github.com/mikizhu520/MikiReminder")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            Divider()
                .opacity(isDark ? 0.3 : 0.1)

            // 描述
            Text("macOS 护眼休息提醒软件\n20-20-20 法则 · 眨眼/站立/喝水提醒")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)

            // 版权
            Text("Copyright © 2026 Miki Zhu. All rights reserved.")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.bottom, 16)
        }
        .frame(width: 360)
        .background(isDark ? Color(NSColor.windowBackgroundColor) : Color(NSColor.windowBackgroundColor))
    }

    private func infoRow(icon: String, title: String, value: String, link: String? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)

            if let link = link, let url = URL(string: link) {
                Link(destination: url) {
                    Text(value)
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            } else {
                Text(value)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
    }
}
