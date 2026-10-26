#!/usr/bin/env bash
# =============================================================================
# tv-fresh v2.0 — 小米电视改造增强版 (免 root, 可逆, 带快照/自动发现/健康检查)
# 原项目: https://github.com/wangrongding/tv-fresh (MIT License)
# 复刻日期: 2026-10-26, 详见 REPRODUCTION-NOTES.md
#
# 用法:
#   mitv-debloat.sh scan                          # 自动扫描局域网 5555 端口发现电视
#   mitv-debloat.sh list [TV_IP]                  # 列出广告组件状态 / HOME 候选
#   mitv-debloat.sh snapshot [TV_IP]              # 快照关键包状态 (清理前必做)
#   mitv-debloat.sh debloat [--soft] [TV_IP]      # 分级清理: 默认 core+optional, --soft 只清核心
#   mitv-debloat.sh restoreall [TV_IP]            # 按快照一键整体还原
#   mitv-debloat.sh health [TV_IP]                # 健康检查 (关键组件/HOME/设置包)
#   mitv-debloat.sh sweep [--soft] [TV_IP]        # 一键流程: 自动发现->快照->清理->体检
#   (兼容 v1) install|switchhome|restorehome|perm|restore <...>
#
# 原则: 系统包只 pm uninstall --user 0 (系统分区不动, install-existing 可还原)
# =============================================================================
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${TV_FRESH_STATE:-$HOME/.tv-fresh}"
LOG_FILE="$STATE_DIR/tv-fresh.log"
SNAPSHOT_FILE="$STATE_DIR/tv_snapshot.txt"
TV_PORT=5555
mkdir -p "$STATE_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

# ---- 分级组件清单 (社区验证) ----
AD_PKGS_CORE=(
  com.miui.systemAdSolution        # 系统广告引擎(横幅/开屏, 核心)
  com.mitv.tvad                    # 电视广告
  com.xiaomi.mitv.advertise        # 广告服务
  com.miui.analytics               # 行为统计
  com.miui.tv.analytics            # 电视统计
  com.mitv.analysis                # 行为统计
)
AD_PKGS_OPTIONAL=(
  com.duokan.videodaily            # 今日头屏
  com.xiaomi.mitv.tvpush           # 消息推送弹窗
  com.xiaomi.mitv.tvpushservice    # 推送服务
  com.xiaomi.mistat.analyticstracker # 埋点上报
  com.xiaomi.tv.musicadapter       # 音乐卡片
  com.xiaomi.mitv.tvmanager        # 电视管家
  com.mitv.shoplugin               # 商城插件
)
PROTECTED_PKGS=(
  com.xiaomi.mitv.settings         # 中文设置(严禁动)
  com.xiaomi.mitv.systemui         # 系统 UI
  com.mitv.tvplayer                # 播放器核心
  com.android.packageinstaller     # 安装器
  com.xiaomi.voicecontrol          # 语音
)

is_core() { local p="$1" c; for c in "${AD_PKGS_CORE[@]}"; do [ "$c" = "$p" ] && return 0; done; return 1; }

# ---- 连接工具 ----
get_local_ip() {
  # Git Bash/Windows: 从 ipconfig 提取第一个非 APIPA 的 IPv4
  ipconfig 2>/dev/null | awk -F': ' '/IPv4/{gsub(/ /,"",$2); if($2 !~ /^169\.254/){print $2; exit}}'
}

detect_tv() {
  local ip net i
  ip="$(get_local_ip)"
  [ -z "$ip" ] && { echo "无法获取本机 IP, 请手动指定 TV_IP" >&2; return 1; }
  net="$(echo "$ip" | awk -F. '{print $1"."$2"."$3"."}')"
  echo "本机 IP: $ip, 扫描 ${net}0/24 的 5555 端口 ..." >&2
  local found=0
  for i in $(seq 1 254); do
    ( timeout 2 adb connect "${net}${i}:$TV_PORT" 2>/dev/null | grep -qi "connected" && echo "${net}${i}" ) &
  done
  wait
  return 0
}

connect() {
  [ -z "$TV_IP" ] && { echo "用法: $0 <命令> [--soft] <TV_IP>, 或先执行 scan"; exit 1; }
  adb disconnect >/dev/null 2>&1
  if ! adb connect "$TV_IP:$TV_PORT" | grep -qi "connected"; then
    echo "连接失败: 检查电视『账号与安全→ADB调试』; 首次连接需遥控器点『允许』"
    exit 1
  fi
  log "已连接 $TV_IP:$TV_PORT"
}

tv_pkg_list() { adb shell pm list packages | sed 's/package://' | tr -d '\r' | sort > "$STATE_DIR/tv_pkgs.txt"; }

# ---- 命令实现 ----
cmd_scan() { detect_tv; }

cmd_list() {
  connect; tv_pkg_list
  echo "== 广告相关组件状态:"
  for p in "${AD_PKGS_CORE[@]}" "${AD_PKGS_OPTIONAL[@]}"; do
    grep -qx "$p" "$STATE_DIR/tv_pkgs.txt" && echo "  $p  [存在]"
  done
  echo "== 桌面(HOME)解析结果:"
  adb shell cmd package resolve-activity --brief -c android.intent.category.HOME 2>/dev/null | tail -1
}

cmd_snapshot() {
  connect; tv_pkg_list
  {
    echo "# tv-fresh snapshot $(date '+%Y-%m-%d %H:%M:%S') @ $TV_IP"
    echo "# 格式: 关键包|状态(installed/uninstalled)"
    for p in "${AD_PKGS_CORE[@]}" "${AD_PKGS_OPTIONAL[@]}" com.mitv.tvhome com.android.tv.settings; do
      if grep -qx "$p" "$STATE_DIR/tv_pkgs.txt"; then echo "$p|installed"; else echo "$p|uninstalled"; fi
    done
  } > "$SNAPSHOT_FILE"
  log "快照已保存: $SNAPSHOT_FILE"
  echo "OK 快照已保存: $SNAPSHOT_FILE"
}

cmd_debloat() {
  local mode="$1"
  connect; tv_pkg_list
  echo "== 分级清理 (mode: $mode)"
  local removed=0 skipped=0 p
  for p in "${AD_PKGS_CORE[@]}" "${AD_PKGS_OPTIONAL[@]}"; do
    [ "$mode" = "soft" ] && ! is_core "$p" && continue
    if grep -qx "$p" "$STATE_DIR/tv_pkgs.txt"; then
      if adb shell pm uninstall --user 0 "$p" >/dev/null 2>&1; then
        echo "OK 已清理 $p"; log "debloat: $p"; removed=$((removed+1))
      else
        echo "FAIL 清理失败 $p"; skipped=$((skipped+1))
      fi
    else
      echo "-- $p (未安装, 跳过)"
    fi
  done
  echo "== 完成: 清理 $removed 项, 失败/跳过 $skipped 项"
}

cmd_restoreall() {
  [ -f "$SNAPSHOT_FILE" ] || { echo "没有快照文件, 请先执行 snapshot"; exit 1; }
  connect
  echo "== 按快照整体还原:"
  local restored=0
  while IFS='|' read -r pkg status; do
    case "$pkg" in \#*|"") continue;; esac
    if [ "$status" = "uninstalled" ]; then
      adb shell cmd package install-existing "$pkg" >/dev/null 2>&1 \
        && { echo "OK 已还原 $pkg"; log "restoreall: $pkg"; restored=$((restored+1)); }
    fi
  done < "$SNAPSHOT_FILE"
  adb shell pm enable com.android.tv.settings >/dev/null 2>&1 && echo "OK 设置包已启用"
  echo "== 还原完成 (共 $restored 项)"
}

cmd_health() {
  connect; tv_pkg_list
  echo "== 连接: $TV_IP"
  echo "-- 关键组件存在性:"
  local ok=1 p
  for p in "${PROTECTED_PKGS[@]}"; do
    if grep -qx "$p" "$STATE_DIR/tv_pkgs.txt"; then echo "  OK $p"; else echo "  MISS $p"; ok=0; fi
  done
  echo "-- HOME 解析:"
  adb shell cmd package resolve-activity --brief -c android.intent.category.HOME 2>/dev/null | tail -1
  echo "-- 设置包:"
  adb shell pm list packages -d | tr -d '\r' | grep -q "com.android.tv.settings" \
    && echo "  兜底页宿主已禁用 (换桌面模式)" || echo "  兜底页宿主正常"
  [ "$ok" = 1 ] && echo "== 健康检查通过" || echo "== 发现异常, 建议 restoreall"
}

cmd_sweep() {
  local mode="$1"
  if [ -z "$TV_IP" ]; then
    echo "未指定 TV_IP, 自动扫描..."
    TV_IP="$(detect_tv | grep -E '^[0-9]' | head -1)"
    [ -z "$TV_IP" ] && { echo "扫描未发现电视, 请手动指定 TV_IP"; exit 1; }
    echo "-> 发现电视: $TV_IP"
  fi
  cmd_snapshot
  cmd_debloat "$mode"
  cmd_health
}

# ---- 入口解析 (兼容 v1 子命令) ----
CMD="${1:-}"; [ $# -gt 0 ] && shift || true
SOFT_MODE="full"; TV_IP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --soft) SOFT_MODE="soft"; shift;;
    *) TV_IP="$1"; shift;;
  esac
done

case "$CMD" in
  scan) cmd_scan;;
  list) cmd_list;;
  snapshot) cmd_snapshot;;
  debloat) cmd_debloat "$SOFT_MODE";;
  restoreall) cmd_restoreall;;
  health) cmd_health;;
  sweep) cmd_sweep "$SOFT_MODE";;
  install)
    APK="${LAUNCHER_APK:-/tmp/projectivy.apk}"; connect
    adb install -r "$APK" || { echo "安装失败"; exit 1; }
    echo "Projectivy 已安装";;
  switchhome)
    COMP="${TV_IP}"; TV_IP="${2:-}"
    [ -z "$COMP" ] && { echo "用法: $0 switchhome <TV_IP> <包名/Activity>"; exit 1; }
    connect
    adb shell cmd package set-home-activity "$COMP" && echo "OK 首选桌面已注册: $COMP"
    adb shell pm uninstall --user 0 com.mitv.tvhome >/dev/null 2>&1 && echo "OK PatchWall 已禁用"
    adb shell pm disable-user --user 0 com.android.tv.settings >/dev/null 2>&1 && echo "OK 兜底页宿主已禁用"
    adb shell input keyevent 3
    echo "-> 按 HOME 键验证; 回滚: $0 restorehome <TV_IP>";;
  restorehome)
    connect
    adb shell cmd package install-existing com.mitv.tvhome && echo "OK PatchWall 已恢复"
    adb shell pm enable com.android.tv.settings && echo "OK 兜底页已恢复";;
  perm)
    connect
    for p in com.github.tvbox.osc.tk com.fongmi.android.tv com.huawei.himovceie; do
      adb shell pm grant "$p" android.permission.READ_EXTERNAL_STORAGE 2>/dev/null
      adb shell pm grant "$p" android.permission.WRITE_EXTERNAL_STORAGE 2>/dev/null
      echo "OK $p 存储权限已授予"
    done;;
  restore)
    PKG="${TV_IP}"; TV_IP="${2:-}"
    [ -z "$PKG" ] && { echo "用法: $0 restore <包名> <TV_IP>"; exit 1; }
    connect
    adb shell cmd package install-existing "$PKG" && echo "已还原 $PKG";;
  *)
    echo "命令: scan | list | snapshot | debloat [--soft] | restoreall | health | sweep [--soft] | install | switchhome | restorehome | perm | restore"
    exit 1;;
esac
