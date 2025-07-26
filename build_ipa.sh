#!/bin/bash

# Lumen iOS App IPA构建脚本

echo "🚀 开始构建Lumen IPA文件..."

# 设置项目路径
PROJECT_PATH="Lumen.xcodeproj"
SCHEME="Lumen"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/Lumen.xcarchive"
EXPORT_PATH="./build/ipa"

# 创建构建目录
mkdir -p build

echo "📦 正在Archive..."
xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS"

if [ $? -eq 0 ]; then
    echo "✅ Archive成功"
    
    echo "📱 正在导出IPA..."
    # 创建ExportOptions.plist
    cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>64V8RUAKWF</string>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist ExportOptions.plist

    if [ $? -eq 0 ]; then
        echo "🎉 IPA文件生成成功！"
        echo "📍 位置: $EXPORT_PATH/Lumen.ipa"
        ls -la "$EXPORT_PATH"
    else
        echo "❌ IPA导出失败"
    fi
else
    echo "❌ Archive失败"
fi

# 清理临时文件
rm -f ExportOptions.plist