# 电视代理（Clash Meta）与 YouTube（SmartTube）

## 一、电视独立代理：CMFA

包：[ClashMetaForAndroid](https://github.com/MetaCubeX/ClashMetaForAndroid/releases)
（TV 选 `cmfa-*-armeabi-v7a-release.apk`）

### 配置导入（adb reverse 法，绕开一切网络限制）

```bash
# 1. 电脑上起临时分发（配置文件所在目录）
cd <配置目录> && python3 -m http.server 18972 --bind 0.0.0.0
# 2. 电视 localhost:18972 ↔ 电脑:18972
adb reverse tcp:18972 tcp:18972
# 3. 深链唤起 CMFA 导入页，用户按"确定"保存即可
adb shell am start -a android.intent.action.VIEW \
  -d "clash://install-config?url=http%3A%2F%2F127.0.0.1%3A18972%2Fconfig.yaml&name=TV"
# 4. 用户侧：保存弹窗 → 允许 VPN 授权 → 打开启动开关
```

验证：`adb shell "ip addr show tun0"` 出现 `172.19.0.1` 类地址即 VPN 已起。

### 配置文件要点

- 规则务必含 `GEOIP,CN,DIRECT`：**国内应用直连、节点挂了关 VPN 即可，电视零影响**
- 也可让用户在电脑 FlyingBird/Clash 里导出节点重建配置；或从订阅拉取

### 局域网分发（可选，替代 reverse）

```bash
sudo ufw allow from 192.168.1.0/24 to any port 18972 proto tcp
# 之后电视直接访问 http://<电脑IP>:18972/config.yaml
```

## 二、YouTube = SmartTube

包：[SmartTube](https://github.com/yuliskov/SmartTube/releases)（`*_armeabi-v7a.apk`）

- 开源、无广告、免谷歌服务、4K、SponsorBlock、遥控器友好
- 需要先开 CMFA 的 VPN 才能访问 YouTube
- **不要尝试官方 YouTube**：强依赖 GMS + 设备认证 + Widevine，国产电视无解（除非外接认证盒子）

## 下载技巧

GitHub 大文件直连常被掐断，用断点续传循环；或走本地代理但注意大文件可能被传输损坏（zip 校验把关）：

```bash
for i in $(seq 1 40); do curl -sL -C - -m 40 '<url>' -o app.apk; \
  unzip -t app.apk >/dev/null 2>&1 && break; done
```
