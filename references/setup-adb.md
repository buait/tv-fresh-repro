# 连接电视：解锁开发者模式与 ADB

## 电视侧开启（遥控器）

1. **设置 → 关于 → 「产品型号」（或「版本号」）连按"确定"5-7 次** → 提示已开启开发者模式
2. **设置 → 账号与安全 → ADB 调试 → 允许**（部分固件在 设置 → 通用设置 → 开发者选项）
3. 首次连接电视弹 RSA 授权框 → 选"允许"（勾选"一律允许"）

## 常见坑

| 现象 | 处理 |
|---|---|
| 「账号与安全」里没有 ADB 调试 | 开发者模式没解锁，回第 1 步连按型号 |
| **每次重启后 ADB 自动关闭** | MIUI TV 常见设定；用语音键说"打开设置"→ 账号与安全 → 重新开启 |
| 没有桌面可导航时 | 语音键是系统级的，桌面挂了也能用 |
| unauthorized | 电视屏幕上有授权弹窗没点 |
| 连不上 5555 | 电视与电脑不同网段（访客网络隔离最常见）；电视 2.4G/5G 无所谓，同路由即可 |

## 定位电视 IP

路由器管理页，或对局域网扫 5555 端口：

```bash
seq 1 254 | sed 's/^/192.168.1./' | xargs -P 64 -I{} sh -c \
  'timeout 0.6 bash -c "echo >/dev/tcp/{}/5555" 2>/dev/null && echo "{} is TV"'
```

## 身份/用途确认命令

```bash
adb shell getprop ro.product.model     # 机型
adb shell getprop ro.product.cpu.abi   # armeabi-v7a → 装包选 v7a/32位
adb shell getprop ro.build.version.release
```
