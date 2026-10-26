# 去广告与精简

## 广告/推送/统计组件清单（按固件实测增删，先 `list` 确认存在）

| 包名 | 作用 |
|---|---|
| com.miui.systemAdSolution | 系统广告引擎（核心） |
| com.duokan.videodaily | 今日头屏 |
| com.xiaomi.mitv.tvpush(.tvpushservice) | 消息推送弹窗 |
| com.xiaomi.mitv.advertise | 广告服务 |
| com.mitv.tvad | 电视广告 |
| com.mitv.analysis / com.miui.analytics / com.miui.tv.analytics | 行为统计 |
| com.xiaomi.mistat.analyticstracker | 埋点 |
| com.xiaomi.tv.musicadapter | 音乐卡片 |
| com.xiaomi.mitv.tvmanager | 电视管家 |
| com.mitv.shoplugin | 商城插件（OTA 后可能自愈复活，重删即可） |

```bash
# 存在才删，逐个执行（系统包用 --user 0 可逆）
adb shell pm list packages | grep <包名片段>
adb shell pm uninstall --user 0 <包名>
# 恢复单个：adb shell cmd package install-existing <包名>
```

## 牌照方预装（第三方，可彻底卸载）

`com.cibn.tv`(CIBN) `com.newtv.cboxtv`(未来电视) `com.ktcp.video`(快看)
`com.cmgame.gamehalltv`(移动游戏大厅) `com.tencent.start.tv`(START云游戏)
`com.hunantv.license`(芒果授权组件) —— 用户确认后再卸。

## 红线（绝不动）

`com.android.packageinstaller`、`com.mitv.tvplayer`、`com.xiaomi.mitv.settings`、
`com.xiaomi.mitv.systemui`、`com.xiaomi.voicecontrol`、投屏四件套（miplay/smartshare/airkan/wfdsink）

## 命名陷阱

- `com.xiaoji.tvbox` 名字像 TVBox 分支，**实际是 MAME 街机模拟器**（组件 com.xiaoji.emu.mame），归类前先 `dumpsys package <pkg> | grep -A3 LAUNCHER` 看组件真身

## OTA 后

系统升级可能复活已删组件：重跑一遍删除即可（脚本 `debloat` 子命令）。
