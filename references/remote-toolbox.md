# 远程操控电视的正确姿势（强触发必读）

> 任何"在电视上输入文字 / 点按钮 / 判断界面状态"的操作，先读本篇。
> 三大铁律：**XML 为准、ADBKeyboard 输入、D-pad 激活**。

## 1. uiautomator dump = 唯一可信数据源

```bash
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml .
# 解析 text/bounds/focused/clickable/enabled
```

- 坐标用完就取：**输入法弹出/收起会导致弹窗布局重排**，缓存的坐标会打偏
- 截图+视觉判读只做辅助（有把"未保存"看成"已保存"的实战误读）；敏感内容截图会被审查接口 400

## 2. 输入文字：ADBKeyboard（防全角乱码）

电视输入法会把 `input text 'http://a.b/c'` 变成 `http：／／a。b／c`（`fm`→`父母`都干得出来）。

```bash
adb install ADBKeyboard.apk   # github.com/senzhk/ADBKeyboard
adb shell ime set com.android.adbkeyboard/.AdbIME
adb shell am broadcast -a ADB_CLEAR_TEXT                      # 清空聚焦输入框
adb shell am broadcast -a ADB_INPUT_TEXT --es msg '<文本>'    # 原样注入,支持中文/URL
adb shell ime set com.sohu.inputmethod.sogou.tv/.SogouIME     # 完事恢复搜狗(用户要用拼音)
```

注：ADB_INPUT_TEXT 是"插入到光标处"，先 CLEAR 再注入；光标位置用点击+dump 复核。

## 3. 按钮：很多 TV 控件不认 tap，只认 D-pad

```bash
adb shell input tap X Y        # 有时只是"聚焦"不"激活"，甚至无效
adb shell input keyevent 61    # TAB：输入框/按钮间走焦点（字段间移动首选）
adb shell input keyevent 21/22 # 左右：同行按钮间移动
adb shell input keyevent 20    # 下
adb shell input keyevent 23    # 确定键：激活焦点元素（终极手段）
adb shell input keyevent 3     # HOME
adb shell input keyevent 4     # 返回（也能收起输入法）
```

标准套路：dump 定位 → TAB/方向键把焦点推到目标 → **先 dump 确认 focused="true"** → 23 激活 → dump 复核结果。

## 4. 截图（辅助判断用）

```bash
adb shell screencap -p /sdcard/s.png && adb pull /sdcard/s.png .
```

## 5. 状态探针

```bash
adb shell "dumpsys window windows | grep mCurrentFocus"   # 当前焦点窗口
adb shell "dumpsys activity activities | grep topResumed"
adb shell ip addr show tun0                                 # VPN 是否在跑
```
