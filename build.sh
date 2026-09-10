#!/bin/bash
# LookAwayClone 构建脚本
# 用法: ./build.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCES_DIR="$SCRIPT_DIR/Sources"
RESOURCES_DIR="$SCRIPT_DIR/Resources"
BUILD_DIR="$SCRIPT_DIR/build"
APP_NAME="MikiReminder"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "🔨 开始构建 $APP_NAME..."

# 检查 Swift 编译器
if ! command -v swiftc &> /dev/null; then
    echo "❌ 未找到 swiftc，请安装 Xcode 或 Command Line Tools"
    echo "   安装命令: xcode-select --install"
    exit 1
fi

# 清理旧构建
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 收集所有 Swift 源文件（使用数组处理含空格的路径）
SWIFT_FILES=()
while IFS= read -r -d '' file; do
    SWIFT_FILES+=("$file")
done < <(find "$SOURCES_DIR" -name "*.swift" -print0 | sort -z)
FILE_COUNT=${#SWIFT_FILES[@]}
echo "📦 找到 $FILE_COUNT 个 Swift 源文件"

# 编译
echo "⚙️  编译中..."
swiftc \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -framework AppKit \
    -framework SwiftUI \
    -framework Combine \
    -framework UserNotifications \
    -O \
    "${SWIFT_FILES[@]}"

echo "✅ 编译完成"

# 复制 Info.plist
cp "$RESOURCES_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# 复制应用图标
if [ -f "$RESOURCES_DIR/AppIcon.png" ]; then
    cp "$RESOURCES_DIR/AppIcon.png" "$APP_BUNDLE/Contents/Resources/AppIcon.png"
fi

# 复制 PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Ad-hoc 签名（允许在未签名环境运行）
echo "🔐 进行 Ad-hoc 签名..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || echo "   (跳过签名，可手动执行 codesign)"

echo ""
echo "🎉 构建成功!"
echo "📂 应用位置: $APP_BUNDLE"
echo ""
echo "运行方式:"
echo "  1. 双击 $APP_BUNDLE 启动"
echo "  2. 或在终端执行: open $APP_BUNDLE"
echo "  3. 安装到应用程序: cp -R $APP_BUNDLE /Applications/"
echo ""
