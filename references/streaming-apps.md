# 影视仓 / OK影视(FongMi) / TVBox：配置与坑

三个都是 TVBox 配置方言家族：同一个配置 URL 通吃。

| App | 形态 | 获取 |
|---|---|---|
| TVBox OSC | 瀑布流（老牌，2024 停更边缘） | 各聚合仓库 |
| [FongMi(OK影视)](https://github.com/FongMi/Release) | 搜索型，维护最勤 | `leanback-armeabi_v7a.apk` |
| 影视仓 | 瀑布流 + 站点墙 | 社区聚合仓库搜 "影视仓 TV 32位" |

## 推荐配置源（免电脑免代理，每日自动更新）

```
http://肥猫.net/tv          # 实测可用(40站)
http://www.饭太硬.net/tv     # 返回图片页,非直连配置
http://fty.xxooo.cf/tv      # 备用,时活时死
http://我不是.摸鱼儿.top     # 备用,时活时死
```

接口是社区维护的，时活时死。装前先验证：`curl -sL -A 'okhttp/3.15' <url>` 返回 JSON 且含 `sites[]` 才算活。

## 配置注入流程（以影视仓为例，全家族通用）

1. 装好 App → 首启过免责声明（**组合键：`下 → 右 → 确定`**，纯点击无效）
2. 进「配置」页 → 焦点放名字框
3. 按 [remote-toolbox](remote-toolbox.md) 注入：
   - 名字框：`CDN聚合`；链接框：上面的 URL（**TAB 键在字段间移动，别信坐标**）
4. `TAB TAB → 左移 → 确定键` 保存（D-pad 激活，见 toolbox）
5. 重启 App 验证站点加载

## 必知坑

| 坑 | 解法 |
|---|---|
| 部分聚合源**首个站点可能是成人站** | 装好后立刻按**遥控器菜单键**(keyevent 82)呼出"选择首页数据源"，切常规站 |
| `pm clear` 后"确定"按不动 | 存储权限丢了：`pm grant <pkg> android.permission.READ_EXTERNAL_STORAGE` + WRITE |
| 饭太硬等接口域名失效 | 先诊断：`getent hosts www.饭太硬.com` 若解析到 157.240.x.x（Facebook 段）= DNS 污染，换源别硬等 |
| 想给 mytv 等直播 App 喂源 | 配置里的 `lives` 段可导出为 txt/m3u 单独用 |

## 存储权限一键补

`scripts/mitv-debloat.sh perm <TV_IP>`（覆盖 TVBox/FongMi/影视仓）
