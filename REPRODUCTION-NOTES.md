# 复现说明（REPRODUCTION NOTES）

本仓库是对原项目的独立复刻与增强版，与上游仓库无任何提交关系（已去除 .git 历史，重新初始化）。

## 原仓库信息

| 项 | 值 |
|---|---|
| 原仓库 | https://github.com/wangrongding/tv-fresh |
| 原仓库许可证 | MIT License (Copyright (c) 2026 wangrongding) |
| 复现日期 | 2026-10-26 |
| 复现方式 | `git clone --depth 1` 浅克隆 → 复制到新目录跳过 .git → 重新 `git init` |

## 复现方式说明

1. 通过 GitHub Trending / gh api 多源检索，选定本日热门 agent 实际运用项目 `wangrongding/tv-fresh`（小米电视改造 Agent Skill，体量 320KB，结构清晰）；
2. `git clone --depth 1 <仓库URL>` 克隆到中间产物目录；
3. 复制文件到独立目录（跳过 .git），彻底断开与原仓库的血缘；
4. 在原项目基础上完成优化（见下），并完整保留 LICENSE 文件；
5. 重新 `git init` 并以独立身份提交推送。

## 优化内容（tv-fresh v1.0 → v2.0）

原版脚本 `scripts/mitv-debloat.sh` 仅支持「手动填 IP + 固定清单清理 + 单包还原」。本复刻版升级为 v2.0：

1. **局域网自动发现电视（`scan`）**：从本机 IP 推断 /24 网段，并发探测 5555 端口，省去手动翻路由器找 IP；
2. **关键包快照备份（`snapshot`）**：清理前把广告组件 / PatchWall / 设置包的 installed/uninstalled 状态写入 `~/.tv-fresh/tv_snapshot.txt`，形成还原依据；
3. **分级清理（`debloat [--soft]`）**：组件拆分为 core（核心广告引擎，全机型验证）与 optional（推送/统计/卡片），谨慎用户可用 `--soft` 只清核心；
4. **一键整体还原（`restoreall`）**：从「单包 restore」升级为「按快照整体还原」，广告组件 + PatchWall + 设置包一次恢复；
5. **健康检查（`health`）**：清理后自动复核关键保护组件存在性、HOME 解析结果、设置包状态，避免换桌面黑屏隐患；
6. **一键流程（`sweep`）**：自动发现 → 快照 → 清理 → 体检，一条命令走完整个改造流程；
7. **执行日志**：每次操作追加写入 `~/.tv-fresh/tv-fresh.log`，全程可追溯；
8. **SKILL.md / README.md 同步升级**：v2.0 命令速查、安全规则补充「清理前先 snapshot / 出问题 restoreall」。

所有系统级操作仍坚持「只 `pm uninstall --user 0`（可逆）+ `install-existing` 还原」的安全底线，系统分区不动。

## 维护记录表

| 日期 | 维护人 | 内容 |
|---|---|---|
| 2026-10-26 | buait | 复刻 wangrongding/tv-fresh v1.0，升级脚本为 v2.0（scan / snapshot / debloat --soft / restoreall / health / sweep / 日志），更新 SKILL.md 与 README.md，保留 LICENSE |
