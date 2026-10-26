# 批量清理预装与权限修复

## 流程

1. **盘点**：`adb shell pm list packages -3`（第三方）+ `pm list packages`（全部）
2. **归类**：给用户一张编号表（应用名/包名/类型/是否可逆），让用户挑编号
3. **执行**：第三方用 `adb uninstall`（彻底）；系统包用 `pm uninstall --user 0`（可逆）
4. **交付**：附恢复命令清单

> 危险判断拿不准的包：`adb shell dumpsys package <pkg> | grep -A3 LAUNCHER` 看组件真身再归类。

## 权限修复（存储权限被"拒绝且不再询问"USER_FIXED 后应用静默残废）

```bash
adb shell pm grant <pkg> android.permission.READ_EXTERNAL_STORAGE
adb shell pm grant <pkg> android.permission.WRITE_EXTERNAL_STORAGE
adb shell pm clear <pkg>   # 清数据后权限会丢，记得重授
```

## 已验证可安全删除的预装（用户确认后）

牌照方内容：cibn/newtv/ktcp/xiaodianshi(yst)；推广：cmgame/tencent.start.tv/hunantv.license；
小米系冗余：alarmcenter/karaoke.service/shoplugin/tvmanager/gallery×2/mediaexplorer/
healthdiagnosis/appstore(用户拍板)/cloudcontrol/tvqs（见 debloat.md 红线外的清单）
