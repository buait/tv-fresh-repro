---
name: tv-fresh
version: 2.0.0
description: "小米电视(MIUI TV)改造技能：去广告、换桌面、装代理/YouTube/影视仓、批量清理预装、远程操控电视。v2.0 新增：局域网自动发现电视(scan)、关键包快照备份(snapshot)、分级清理(debloat --soft)、一键整体还原(restoreall)、健康检查(health)、一键流程(sweep)。当用户提到小米电视/Redmi电视/电视盒子去广告、换Launcher、TVBox/影视仓配置、电视装代理或YouTube、adb 操作电视时使用。需要电视与电脑同网且开启 ADB 调试。"
metadata:
  requires:
    bins: ["adb", "timeout"]
---

# 小米电视改造（mitv-mod）

免 root 改造国内 MIUI TV。所有系统级操作均为 `pm uninstall --user 0`（可逆），
每个任务都附恢复命令。实测机型：MiTV-ASTP0 / Android 9 / armeabi-v7a。

## 前置：连接电视

```bash
adb connect <TV_IP>:5555
adb devices   # device=通 / unauthorized=电视上有授权弹窗等用户点
```

电视侧开 ADB 的路径、以及"每次重启 ADB 被复位"的应对 → 见 [`references/setup-adb.md`](references/setup-adb.md)

## 任务路由（按用户需求读对应 reference，再动手）

| 用户想做的事 | 必读 |
|---|---|
| 去广告 / 精简系统 | [`references/debloat.md`](references/debloat.md) |
| 换桌面（开机进第三方 Launcher） | [`references/launcher-swap.md`](references/launcher-swap.md) |
| 电视装代理（Clash Meta） | [`references/proxy-youtube.md`](references/proxy-youtube.md) |
| 电视看 YouTube | [`references/proxy-youtube.md`](references/proxy-youtube.md) |
| 装/配 影视仓、OK影视(FongMi)、TVBox | [`references/streaming-apps.md`](references/streaming-apps.md) |
| 批量卸预装 / 修权限 | [`references/cleanup-permissions.md`](references/cleanup-permissions.md) |
| **任何"在电视上输文字/点按钮/看界面"的操作** | [`references/remote-toolbox.md`](references/remote-toolbox.md) ← 强制先读 |
| **安装任何 APK 之前** | [`references/app-sources.md`](references/app-sources.md) ← 只用实测源+装后核对包名 |

## 一键脚本 (v2.0)

[`scripts/mitv-debloat.sh`](scripts/mitv-debloat.sh)

| 命令 | 作用 | 示例 |
|---|---|---|
| `scan` | 自动扫描局域网 5555 端口发现电视 | `./mitv-debloat.sh scan` |
| `list [IP]` | 列出广告组件状态与 HOME 候选 | `./mitv-debloat.sh list 192.168.1.4` |
| `snapshot [IP]` | 记录关键包状态到快照文件（清理前必做） | `./mitv-debloat.sh snapshot 192.168.1.4` |
| `debloat [--soft] [IP]` | 分级清理；默认 core+optional，`--soft` 只清核心广告 | `./mitv-debloat.sh debloat --soft 192.168.1.4` |
| `restoreall [IP]` | 按快照一键整体还原（广告组件+PatchWall+设置包） | `./mitv-debloat.sh restoreall 192.168.1.4` |
| `health [IP]` | 健康检查（关键组件/HOME/设置包） | `./mitv-debloat.sh health 192.168.1.4` |
| `sweep [--soft] [IP]` | 一键流程：自动发现→快照→清理→体检 | `./mitv-debloat.sh sweep 192.168.1.4` |

兼容 v1：`install | switchhome | restorehome | perm | restore <包名> [IP]`。

## 硬性安全规则

1. **系统包只用 `pm uninstall --user 0`**（可逆），绝不用 `pm uninstall -k --user 0` 之外的彻底删除；第三方预装才用 `adb uninstall`
2. **禁用/卸载任何系统包前，向用户展示清单并获确认**；执行后立刻给出对应恢复命令
3. **绝不动**：`com.xiaomi.mitv.settings`（中文设置）、`com.xiaomi.mitv.systemui`、`com.mitv.tvplayer`、`com.android.packageinstaller`、`com.xiaomi.voicecontrol`（语音）、投屏相关（miplay/smartshare/airkan/wfdsink）
4. 桌面操作黑屏时立即回滚：`adb shell cmd package install-existing com.mitv.tvhome`
5. 电视上输入文字前必读 remote-toolbox（电视输入法会把 ASCII 转全角，直接 `input text` 必产出乱码）
6. **v2.0 约定：批量清理前先 `snapshot`**，出问题用 `restoreall` 整体还原；清理后跑 `health` 复核

## 验证原则

- 界面状态以 `uiautomator dump` 的 XML 为准，截图+视觉判读仅做辅助（有误读先例）
- 每步操作后 dump 复核（弹窗是否关闭/字段是否正确），不凭命令返回值推断界面
