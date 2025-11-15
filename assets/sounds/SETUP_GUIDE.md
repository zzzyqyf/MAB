# ⚠️ IMPORTANT: Add beep.mp3 File

## Quick Setup (选择一个方法)

### 方法 1: 下载现成的 Beep 音效（最简单）

1. 访问: https://pixabay.com/sound-effects/search/alarm/
2. 搜索 "beep" 或 "alarm"
3. 下载一个短促的beep音效（0.3-0.5秒）
4. 重命名为 `beep.mp3`
5. 放到这个文件夹

**推荐音效**:
- "Beep Short" - 简短清脆的beep声
- "Alert Beep" - 警报类beep
- "Notification Beep" - 通知类beep

### 方法 2: 在线生成 Beep 音效

1. 访问: https://onlinetonegenerator.com/
2. 设置:
   - **Frequency**: 1000 Hz (高音调，容易注意到)
   - **Duration**: 0.5 seconds
   - **Waveform**: Sine (正弦波，最纯净)
3. 点击 "Play" 测试声音
4. 点击 "Download" 下载为 MP3
5. 重命名为 `beep.mp3`
6. 放到这个文件夹

### 方法 3: 使用 Audacity（免费软件）

```bash
# 1. 下载 Audacity
https://www.audacityteam.org/

# 2. 在 Audacity 中:
Generate → Tone...
  - Waveform: Sine
  - Frequency: 1000 Hz
  - Amplitude: 0.8
  - Duration: 0.5 seconds
  
# 3. 导出:
File → Export → Export as MP3
Save as: beep.mp3
```

### 方法 4: 使用现有音乐软件

如果你有 GarageBand, FL Studio, 或其他音乐软件，可以生成一个简单的 1000Hz 正弦波，持续 0.5 秒。

## 临时测试方案

如果暂时没有 beep.mp3 文件，代码会自动 fallback 到:
1. Android ToneGenerator (原来的方法)
2. 振动反馈

但**强烈建议添加 beep.mp3** 以获得最佳体验！

## 验证文件

添加文件后，确保：
- ✅ 文件名完全是 `beep.mp3` (小写)
- ✅ 文件在 `assets/sounds/` 文件夹
- ✅ 文件大小 < 100 KB
- ✅ 可以在手机/电脑上播放

## 文件应该在这里:

```
MAB/
  assets/
    sounds/
      beep.mp3  ← 把文件放这里！
      README.md
      SETUP_GUIDE.md (this file)
```

## 测试命令

添加文件后，运行:

```powershell
# 重新获取依赖
flutter pub get

# 清理并重新构建
flutter clean
flutter run --release
```

## 推荐音效特性

- **格式**: MP3
- **时长**: 0.3 - 0.5 秒 (短促有力)
- **频率**: 800-1200 Hz (高音调容易引起注意)
- **响度**: 标准化/最大化 (loud and clear)
- **文件大小**: < 50 KB

## 故障排除

如果没声音:
1. 确认文件名正确: `beep.mp3`
2. 确认文件在正确位置
3. 运行 `flutter pub get`
4. 运行 `flutter clean`
5. 重新构建 app
6. 检查手机媒体音量（不是alarm volume）
