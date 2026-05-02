# System Alerts to Telegram

A lightweight VPS monitoring job that sends Telegram alerts for resource pressure, service outages, security events, deploy failures, certificate expiration, and more — with severity tiers (🔴 CRITICAL / 🟡 WARNING / 🔵 INFO), per-alert dedup with TTL, and an optional daily heartbeat.

## What it monitors

**Resources**
- Disk usage per filesystem (`DISK_THRESHOLD`, default 85%)
- Inode usage per filesystem (`INODE_THRESHOLD`, default 85%)
- Memory + top RAM consumers (`MEM_THRESHOLD`, default 85%)
- Swap usage (`SWAP_THRESHOLD`, default 50%)
- Load average vs. core count + top CPU consumers (`CPU_LOAD_FACTOR`, default 1.5×)
- I/O wait (`IOWAIT_THRESHOLD`, default 30%)
- Zombie processes (`ZOMBIE_THRESHOLD`, default 5)

**Services & system**
- Specified services down (`SERVICES`, default `docker dokploy nginx cron ssh fail2ban`)
- Any failed `systemctl --failed` units
- OOM-killer activity in journal
- Kernel I/O / EXT4 / MCE errors in dmesg
- Critical journal entries (priority ≤ 2) since last run

**Security & access**
- SSH failed login bursts with top source IPs (`SSH_FAIL_THRESHOLD`, default 20)
- Successful root SSH login (always critical)
- All successful SSH logins (info level)
- fail2ban currently-banned counter
- Public IP drift
- Listening port set diff (catches new/missing services)

**Updates**
- Security updates available (separate from generic upgradable count)
- Reboot required flag (`/var/run/reboot-required`)

**Docker / Dokploy**
- Unhealthy containers
- Containers exited with non-zero status
- Restart loops (>5 restarts)
- Disk pressure on `DockerRootDir`
- Dokploy log files with deploy failure markers

**Certificates**
- Remote SSL probe for domains in `SSL_DOMAINS`
- Local Let's Encrypt certs in `/etc/letsencrypt/live/`
- Warns at `SSL_DAYS_WARN` days remaining (default 14), critical when expired

**Connections**
- Established TCP connections (`CONN_THRESHOLD`, default 2000)

## 1) Create a Telegram bot

1. Open Telegram and start a chat with **BotFather**.
2. Create a new bot and copy the **bot token**.
3. Send a message to the bot from your account.
4. Get your **chat ID** (use a helper bot like `@RawDataBot` or check the update payload at `https://api.telegram.org/bot<TOKEN>/getUpdates`).

## 2) Create the environment file

```bash
sudo install -d -m 700 /etc/telegram-alerts
sudo nano /etc/telegram-alerts/env
```

Minimum content:

```bash
TELEGRAM_TOKEN=YOUR_BOT_TOKEN
TELEGRAM_CHAT_ID=YOUR_CHAT_ID
```

Recommended full content (everything optional except the two credentials):

```bash
# --- credentials -------------------------------------------------------------
TELEGRAM_TOKEN=YOUR_BOT_TOKEN
TELEGRAM_CHAT_ID=YOUR_CHAT_ID

# --- services to monitor (space-separated) -----------------------------------
SERVICES="docker dokploy nginx cron ssh fail2ban"

# --- SSL domains for remote probe (space-separated, leave empty to skip) -----
SSL_DOMAINS="example.com api.example.com"

# --- thresholds (override only if defaults don't fit) ------------------------
# DISK_THRESHOLD=85          # %, per filesystem
# INODE_THRESHOLD=85         # %, per filesystem
# MEM_THRESHOLD=85           # %
# SWAP_THRESHOLD=50          # %
# CPU_LOAD_FACTOR=1.5        # load1 must exceed cores * factor
# IOWAIT_THRESHOLD=30        # %
# SSH_FAIL_THRESHOLD=20      # failed logins per run
# CONN_THRESHOLD=2000        # established TCP connections
# SSL_DAYS_WARN=14           # warn when cert expires in fewer days
# ZOMBIE_THRESHOLD=5

# --- alert behavior ----------------------------------------------------------
# DEDUP_TTL=3600             # seconds before identical alert can fire again
# HEARTBEAT_HOUR=09          # hour (00–23) for daily "all green" message; unset = disabled
```

Lock it down:

```bash
sudo chmod 600 /etc/telegram-alerts/env
```

## 3) Create the alert script

```bash
sudo nano /usr/local/sbin/telegram-alerts.sh
```

Paste the full script below:

```bash
#!/usr/bin/env bash
# =============================================================================
#  telegram-alerts.sh — comprehensive server monitoring with Telegram alerts
# -----------------------------------------------------------------------------
#  ENV FILE: /etc/telegram-alerts/env  (chmod 600, owner root)
#    TELEGRAM_TOKEN="123456:ABC..."
#    TELEGRAM_CHAT_ID="-1001234567890"
#    # optional overrides:
#    # SERVICES="docker dokploy nginx cron ssh fail2ban"
#    # SSL_DOMAINS="example.com api.example.com"
#    # DISK_THRESHOLD=85   INODE_THRESHOLD=85
#    # MEM_THRESHOLD=85    SWAP_THRESHOLD=50
#    # CPU_LOAD_FACTOR=1.5 IOWAIT_THRESHOLD=30
#    # SSH_FAIL_THRESHOLD=20  CONN_THRESHOLD=2000
#    # SSL_DAYS_WARN=14       ZOMBIE_THRESHOLD=5
#    # DEDUP_TTL=3600         HEARTBEAT_HOUR=09
#
#  CRON: */5 * * * * root /usr/local/sbin/telegram-alerts.sh
# =============================================================================

set -u
umask 077
export LC_ALL=C
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ENV_FILE="${ENV_FILE:-/etc/telegram-alerts/env}"
STATE_DIR="${STATE_DIR:-/var/lib/telegram-alerts}"
STATE_FILE="$STATE_DIR/last_run"
MARK_FILE="$STATE_DIR/marker"
LOCK_FILE="$STATE_DIR/lock"
DEDUP_DIR="$STATE_DIR/dedup"
LOG_FILE="${LOG_FILE:-/var/log/telegram-alerts.log}"

# Default thresholds (override in env file)
DISK_THRESHOLD="${DISK_THRESHOLD:-85}"
INODE_THRESHOLD="${INODE_THRESHOLD:-85}"
MEM_THRESHOLD="${MEM_THRESHOLD:-85}"
SWAP_THRESHOLD="${SWAP_THRESHOLD:-50}"
CPU_LOAD_FACTOR="${CPU_LOAD_FACTOR:-1.5}"
IOWAIT_THRESHOLD="${IOWAIT_THRESHOLD:-30}"
SSH_FAIL_THRESHOLD="${SSH_FAIL_THRESHOLD:-20}"
CONN_THRESHOLD="${CONN_THRESHOLD:-2000}"
SSL_DAYS_WARN="${SSL_DAYS_WARN:-14}"
ZOMBIE_THRESHOLD="${ZOMBIE_THRESHOLD:-5}"
DEDUP_TTL="${DEDUP_TTL:-3600}"
SERVICES="${SERVICES:-docker dokploy nginx cron ssh fail2ban}"
SSL_DOMAINS="${SSL_DOMAINS:-}"

[ -r "$ENV_FILE" ] || exit 0
# shellcheck disable=SC1090
source "$ENV_FILE"

mkdir -p "$STATE_DIR" "$DEDUP_DIR"

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*" >>"$LOG_FILE" 2>/dev/null || true; }

# ---------- state ------------------------------------------------------------
now=$(date +%s)
if [ ! -f "$STATE_FILE" ]; then
  printf '%s' "$now" >"$STATE_FILE"
  touch -d "@$now" "$MARK_FILE"
  exit 0
fi
last=$(cat "$STATE_FILE" 2>/dev/null || echo "$now")
[ "$last" -gt 0 ] 2>/dev/null || last="$now"
touch -d "@$last" "$MARK_FILE"
since_iso=$(date -d "@$last" '+%F %T' 2>/dev/null || echo "1 hour ago")

# ---------- alert collection -------------------------------------------------
declare -a CRIT=() WARN=() INFO=()

esc_html() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

dedup_check() {
  local hash; hash=$(printf '%s' "$1" | sha1sum | cut -d' ' -f1)
  local f="$DEDUP_DIR/$hash"
  if [ -f "$f" ]; then
    local age=$(( now - $(stat -c %Y "$f" 2>/dev/null || echo 0) ))
    [ "$age" -lt "$DEDUP_TTL" ] && return 1
  fi
  touch "$f"; return 0
}

add_crit() { dedup_check "C:$1" && CRIT+=("$1") || true; }
add_warn() { dedup_check "W:$1" && WARN+=("$1") || true; }
add_info() { dedup_check "I:$1" && INFO+=("$1") || true; }

send_telegram() {
  local msg="$1"
  [ -n "$msg" ] || return 0
  [ -n "${TELEGRAM_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ] || return 0
  if [ "${#msg}" -gt 4000 ]; then
    msg="${msg:0:3950}"$'\n…(truncated)'
  fi
  curl -fsS --max-time 15 -X POST \
    "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    -d disable_web_page_preview=true \
    --data-urlencode text="$msg" >/dev/null 2>&1 \
    || log "telegram send failed"
}

# =============================================================================
#  CHECKS
# =============================================================================

check_disk() {
  while IFS= read -r line; do
    add_crit "💾 Disk usage: $line"
  done < <(
    df -P -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null \
      | awk -v t="$DISK_THRESHOLD" 'NR>1 && ($5+0)>=t {print $5" "$6" ("$1")"}'
  )
}

check_inodes() {
  while IFS= read -r line; do
    add_crit "📂 Inode usage: $line"
  done < <(
    df -Pi -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null \
      | awk -v t="$INODE_THRESHOLD" 'NR>1 && ($5+0)>=t {print $5" "$6}'
  )
}

check_memory() {
  local mem swap top
  mem=$(free | awk '/^Mem:/ {if ($2>0) printf("%.0f",($3/$2)*100)}')
  if [ -n "$mem" ] && [ "$mem" -ge "$MEM_THRESHOLD" ] 2>/dev/null; then
    top=$(ps -eo pid,user,%mem,comm --sort=-%mem 2>/dev/null \
          | awk 'NR>1 && NR<=6 {printf "  %s %s %s%% %s\n",$1,$2,$3,$4}')
    add_warn "🧠 Memory high: ${mem}%
Top:
$top"
  fi
  swap=$(free | awk '/^Swap:/ {if ($2>0) printf("%.0f",($3/$2)*100); else print 0}')
  if [ -n "$swap" ] && [ "$swap" -ge "$SWAP_THRESHOLD" ] 2>/dev/null; then
    add_warn "💱 Swap usage: ${swap}%"
  fi
}

check_cpu() {
  local load1 cores top iowait
  load1=$(awk '{print $1}' /proc/loadavg)
  cores=$(nproc)
  if awk -v l="$load1" -v c="$cores" -v f="$CPU_LOAD_FACTOR" \
       'BEGIN{exit !(l > c*f)}'; then
    top=$(ps -eo pid,user,%cpu,comm --sort=-%cpu 2>/dev/null \
          | awk 'NR>1 && NR<=6 {printf "  %s %s %s%% %s\n",$1,$2,$3,$4}')
    add_warn "⚙️ CPU/load high: load1=${load1}, cores=${cores}
Top:
$top"
  fi
  if command -v vmstat >/dev/null 2>&1; then
    iowait=$(vmstat 1 2 2>/dev/null | tail -1 | awk '{print $16}')
    if [ -n "$iowait" ] && [ "$iowait" -ge "$IOWAIT_THRESHOLD" ] 2>/dev/null; then
      add_warn "💽 I/O wait high: ${iowait}%"
    fi
  fi
}

check_zombies() {
  local n
  n=$(ps -eo stat= 2>/dev/null | awk '/^Z/' | wc -l)
  if [ "$n" -ge "$ZOMBIE_THRESHOLD" ] 2>/dev/null; then
    add_warn "🧟 Zombie processes: $n"
  fi
}

check_services() {
  for svc in $SERVICES; do
    systemctl list-unit-files "${svc}.service" 2>/dev/null \
      | grep -q "${svc}.service" || continue
    systemctl is-active --quiet "$svc" 2>/dev/null \
      || add_crit "🛑 Service down: $svc"
  done
  while IFS= read -r unit; do
    [ -n "$unit" ] && add_warn "🔴 Failed unit: $unit"
  done < <(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}')
}

check_ssh_fails() {
  command -v journalctl >/dev/null 2>&1 || return 0
  local count top_ips root_ok
  count=$(journalctl --since "$since_iso" -u ssh -u sshd --no-pager 2>/dev/null \
          | grep -ciE 'Failed password|Invalid user|authentication failure')
  count=${count:-0}
  if [ "$count" -ge "$SSH_FAIL_THRESHOLD" ] 2>/dev/null; then
    top_ips=$(journalctl --since "$since_iso" -u ssh -u sshd --no-pager 2>/dev/null \
      | grep -E 'Failed password|Invalid user' \
      | grep -oE 'from [0-9a-f.:]+' | awk '{print $2}' \
      | sort | uniq -c | sort -rn | head -5 \
      | awk '{printf "  %s × %s\n",$1,$2}')
    add_crit "🔐 SSH failed logins: $count since $since_iso
$top_ips"
  fi
  root_ok=$(journalctl --since "$since_iso" -u ssh -u sshd --no-pager 2>/dev/null \
            | grep -cE 'Accepted .* for root from')
  root_ok=${root_ok:-0}
  if [ "$root_ok" -gt 0 ] 2>/dev/null; then
    add_crit "🚨 Successful SSH root login(s): $root_ok"
  fi
}

check_successful_logins() {
  command -v journalctl >/dev/null 2>&1 || return 0
  local lines
  lines=$(journalctl --since "$since_iso" -u ssh -u sshd --no-pager 2>/dev/null \
    | grep -E 'Accepted (publickey|password)' \
    | sed -E 's/.*Accepted (publickey|password) for ([^ ]+) from ([^ ]+).*/  \2 from \3 (\1)/' \
    | sort -u | head -10)
  [ -n "$lines" ] && add_info "👤 SSH logins since $since_iso:
$lines"
}

check_fail2ban() {
  command -v fail2ban-client >/dev/null 2>&1 || return 0
  systemctl is-active --quiet fail2ban 2>/dev/null || return 0
  local jails total=0 b
  jails=$(fail2ban-client status 2>/dev/null \
          | awk -F: '/Jail list/ {gsub(/[ \t,]/," ",$2); print $2}')
  for j in $jails; do
    [ -z "$j" ] && continue
    b=$(fail2ban-client status "$j" 2>/dev/null \
        | awk -F: '/Currently banned/ {gsub(/[ \t]/,"",$2); print $2}')
    total=$(( total + ${b:-0} ))
  done
  [ "$total" -ge 10 ] 2>/dev/null \
    && add_info "🛡 fail2ban currently banning $total IP(s)"
}

check_updates() {
  if command -v apt-get >/dev/null 2>&1; then
    local total sec
    total=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
    sec=$(apt list --upgradable 2>/dev/null \
          | grep -ciE '(\-security|security\.ubuntu|security\.debian)')
    if [ "$sec" -gt 0 ] 2>/dev/null; then
      add_warn "🔒 Security updates available: $sec (total upgradable: $total)"
    elif [ "$total" -gt 50 ] 2>/dev/null; then
      add_info "📦 $total packages upgradable"
    fi
  fi
  [ -f /var/run/reboot-required ] \
    && add_warn "🔁 Reboot required (kernel/library update)"
}

check_logs() {
  if [ -d /etc/dokploy/logs ]; then
    while IFS= read -r f; do
      grep -EaiIq '(unauthorized|panic|FATAL|❌|Traceback|exception|deploy.*fail)' \
        "$f" 2>/dev/null \
        && add_warn "📜 Dokploy log issue: $(basename "$f")"
    done < <(find /etc/dokploy/logs -type f -newer "$MARK_FILE" 2>/dev/null \
             | sort | head -20)
  fi
  for d in /var/log/unattended-upgrades /var/log/apt; do
    [ -d "$d" ] || continue
    while IFS= read -r f; do
      grep -EaiIq '(error|failed|Unable to|broken)' "$f" 2>/dev/null \
        && add_info "📦 Update log entry: $(basename "$f")"
    done < <(find "$d" -type f -newer "$MARK_FILE" 2>/dev/null | sort | head -10)
  done
  if command -v journalctl >/dev/null 2>&1; then
    local crit_count
    crit_count=$(journalctl --since "$since_iso" -p 2 --no-pager 2>/dev/null \
                 | grep -vc '^-- ')
    crit_count=${crit_count:-0}
    [ "$crit_count" -gt 5 ] 2>/dev/null \
      && add_warn "📰 $crit_count critical journal entries since $since_iso"
    journalctl --since "$since_iso" --no-pager 2>/dev/null \
      | grep -qE 'Out of memory|oom-killer|invoked oom' \
      && add_crit "💀 OOM-killer activity detected"
    journalctl --since "$since_iso" -k --no-pager 2>/dev/null \
      | grep -qiE 'I/O error|hard error|EXT4-fs error|filesystem error|MCE' \
      && add_crit "🧱 Kernel hardware/filesystem error in dmesg"
  fi
}

check_docker() {
  command -v docker >/dev/null 2>&1 || return 0
  systemctl is-active --quiet docker 2>/dev/null || return 0
  local unh exited rc c
  unh=$(docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null)
  if [ -n "$unh" ]; then
    add_crit "🐳 Unhealthy containers:
$(printf '%s\n' "$unh" | sed 's/^/  /')"
  fi
  exited=$(docker ps -a --filter status=exited --filter status=dead \
           --format '{{.Names}} ({{.Status}})' 2>/dev/null \
           | grep -v 'Exited (0)' | head -10)
  if [ -n "$exited" ]; then
    add_warn "🐳 Containers exited with errors:
$(printf '%s\n' "$exited" | sed 's/^/  /')"
  fi
  while read -r c; do
    [ -z "$c" ] && continue
    rc=$(docker inspect -f '{{.RestartCount}}' "$c" 2>/dev/null)
    [ "${rc:-0}" -gt 5 ] 2>/dev/null \
      && add_warn "🔄 Container restart loop: $c (restarts=$rc)"
  done < <(docker ps --format '{{.Names}}' 2>/dev/null)
  if command -v df >/dev/null 2>&1; then
    local docker_root
    docker_root=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null)
    if [ -n "$docker_root" ] && [ -d "$docker_root" ]; then
      local pct
      pct=$(df -P "$docker_root" 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')
      [ -n "$pct" ] && [ "$pct" -ge "$DISK_THRESHOLD" ] 2>/dev/null \
        && add_warn "🐳 Docker root dir disk: ${pct}% ($docker_root)"
    fi
  fi
}

check_ssl_remote() {
  [ -n "$SSL_DOMAINS" ] || return 0
  command -v openssl >/dev/null 2>&1 || return 0
  for dom in $SSL_DOMAINS; do
    local exp_date exp_ts days_left
    exp_date=$(echo | timeout 10 openssl s_client \
                 -servername "$dom" -connect "${dom}:443" 2>/dev/null \
               | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -z "$exp_date" ]; then
      add_warn "🔏 SSL probe failed: $dom"; continue
    fi
    exp_ts=$(date -d "$exp_date" +%s 2>/dev/null) || continue
    days_left=$(( (exp_ts - now) / 86400 ))
    if [ "$days_left" -lt 0 ] 2>/dev/null; then
      add_crit "🔏 SSL EXPIRED: $dom ($days_left d)"
    elif [ "$days_left" -lt "$SSL_DAYS_WARN" ] 2>/dev/null; then
      add_warn "🔏 SSL expires in $days_left d: $dom"
    fi
  done
}

check_ssl_local() {
  [ -d /etc/letsencrypt/live ] || return 0
  command -v openssl >/dev/null 2>&1 || return 0
  local cert end_ts days_left name
  while IFS= read -r cert; do
    end_ts=$(openssl x509 -in "$cert" -noout -enddate 2>/dev/null \
             | cut -d= -f2 | xargs -I{} date -d "{}" +%s 2>/dev/null)
    [ -z "$end_ts" ] && continue
    days_left=$(( (end_ts - now) / 86400 ))
    name=$(basename "$(dirname "$cert")")
    if [ "$days_left" -lt 0 ] 2>/dev/null; then
      add_crit "🔏 Local cert EXPIRED: $name"
    elif [ "$days_left" -lt "$SSL_DAYS_WARN" ] 2>/dev/null; then
      add_warn "🔏 Local cert expires in $days_left d: $name"
    fi
  done < <(find /etc/letsencrypt/live -name 'fullchain.pem' 2>/dev/null)
}

check_network() {
  if command -v ss >/dev/null 2>&1; then
    local conn
    conn=$(ss -tan state established 2>/dev/null | tail -n +2 | wc -l)
    [ "$conn" -ge "$CONN_THRESHOLD" ] 2>/dev/null \
      && add_warn "🌐 Established connections: $conn"
  fi
  local ip_file="$STATE_DIR/public_ip" cur_ip prev_ip
  cur_ip=$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null \
           || curl -fsS --max-time 5 https://ifconfig.me 2>/dev/null)
  if [ -n "$cur_ip" ]; then
    if [ -f "$ip_file" ]; then
      prev_ip=$(cat "$ip_file" 2>/dev/null)
      [ -n "$prev_ip" ] && [ "$prev_ip" != "$cur_ip" ] \
        && add_crit "🌍 Public IP changed: $prev_ip → $cur_ip"
    fi
    printf '%s' "$cur_ip" >"$ip_file"
  fi
}

check_listening_ports() {
  command -v ss >/dev/null 2>&1 || return 0
  local ports_file="$STATE_DIR/listen_ports" cur prev
  cur=$(ss -tlnH 2>/dev/null \
        | awk '{print $4}' | awk -F: '{print $NF}' \
        | sort -un | tr '\n' ',' | sed 's/,$//')
  if [ -f "$ports_file" ]; then
    prev=$(cat "$ports_file" 2>/dev/null)
    if [ -n "$prev" ] && [ "$prev" != "$cur" ]; then
      add_warn "🔌 Listening ports changed
  before: $prev
  after:  $cur"
    fi
  fi
  printf '%s' "$cur" >"$ports_file"
}

cleanup_dedup() {
  find "$DEDUP_DIR" -type f -mmin +1440 -delete 2>/dev/null || true
}

# =============================================================================
#  RUN
# =============================================================================
check_disk
check_inodes
check_memory
check_cpu
check_zombies
check_services
check_ssh_fails
check_successful_logins
check_fail2ban
check_updates
check_logs
check_docker
check_ssl_remote
check_ssl_local
check_network
check_listening_ports
cleanup_dedup

# =============================================================================
#  REPORT
# =============================================================================
total=$(( ${#CRIT[@]} + ${#WARN[@]} + ${#INFO[@]} ))
if [ "$total" -gt 0 ]; then
  host=$(hostname -f 2>/dev/null || hostname)
  uptime_str=$(uptime -p 2>/dev/null || uptime)
  ts=$(date '+%F %T %Z')

  msg="<b>🖥 ${host}</b>
<i>${ts} • ${uptime_str}</i>"

  if [ "${#CRIT[@]}" -gt 0 ]; then
    block=$(printf -- '• %s\n' "${CRIT[@]}" | esc_html)
    msg+="

<b>🔴 CRITICAL (${#CRIT[@]})</b>
${block}"
  fi
  if [ "${#WARN[@]}" -gt 0 ]; then
    block=$(printf -- '• %s\n' "${WARN[@]}" | esc_html)
    msg+="

<b>🟡 WARNING (${#WARN[@]})</b>
${block}"
  fi
  if [ "${#INFO[@]}" -gt 0 ]; then
    block=$(printf -- '• %s\n' "${INFO[@]}" | esc_html)
    msg+="

<b>🔵 INFO (${#INFO[@]})</b>
${block}"
  fi

  send_telegram "$msg"
  log "alerts: ${#CRIT[@]} crit / ${#WARN[@]} warn / ${#INFO[@]} info"
fi

# Optional daily heartbeat
if [ "${HEARTBEAT_HOUR:-}" != "" ]; then
  hb_file="$STATE_DIR/heartbeat"
  cur_hour=$(date +%H)
  cur_day=$(date +%Y-%m-%d)
  if [ "$cur_hour" = "${HEARTBEAT_HOUR}" ] \
     && [ "$(cat "$hb_file" 2>/dev/null)" != "$cur_day" ]; then
    host=$(hostname -f 2>/dev/null || hostname)
    uptime_str=$(uptime -p 2>/dev/null || uptime)
    df_summary=$(df -h --total -x tmpfs -x devtmpfs 2>/dev/null \
                 | awk '/^total/ {print $5" used ("$3"/"$2")"}')
    mem_summary=$(free -h | awk '/^Mem:/ {print $3"/"$2" used"}')
    send_telegram "<b>💚 Daily heartbeat — ${host}</b>
${uptime_str}
Disk: ${df_summary}
Mem:  ${mem_summary}
Status: all checks green"
    printf '%s' "$cur_day" >"$hb_file"
  fi
fi

# ---------- persist state ----------------------------------------------------
printf '%s' "$now" >"$STATE_FILE"
touch -d "@$now" "$MARK_FILE"
exit 0
```

Make it executable:

```bash
sudo chmod 0755 /usr/local/sbin/telegram-alerts.sh
```

The script auto-creates its state directory (`/var/lib/telegram-alerts/`) on first run and exits silently without sending alerts — that initial run only sets the marker.

## 4) Add the cron job

Run it every 5 minutes via `/etc/cron.d/` (recommended over user crontab so it runs as root with a clean PATH):

```bash
echo '*/5 * * * * root /usr/local/sbin/telegram-alerts.sh' \
  | sudo tee /etc/cron.d/telegram-alerts >/dev/null
sudo chmod 644 /etc/cron.d/telegram-alerts
```

`flock` inside the script prevents overlap if a cycle ever runs long.

## 5) Initialize state

The first execution only initializes state — no alerts are sent. Run it once manually so the second cron tick has a `last_run` to compare against:

```bash
sudo /usr/local/sbin/telegram-alerts.sh
```

## 6) Test the Telegram alert path

```bash
source /etc/telegram-alerts/env
host=$(hostname -f 2>/dev/null || hostname)
curl -fsS -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  -d chat_id="$TELEGRAM_CHAT_ID" \
  -d parse_mode=HTML \
  --data-urlencode text="<b>🖥 ${host}</b>
Test alert: Telegram notifications are working."
```

To trigger a real alert end-to-end, temporarily lower a threshold (e.g. `MEM_THRESHOLD=1`) in the env file, run the script, then revert.

## 7) Severity model

Every alert is bucketed at one of three levels and the report message groups them:

- 🔴 **CRITICAL** — needs immediate attention (service down, root SSH login, OOM, expired cert, IP change, kernel/FS error)
- 🟡 **WARNING** — degradation or pre-failure (memory/swap high, restart loops, security updates pending, cert expiring soon)
- 🔵 **INFO** — for awareness (successful SSH logins, lots of currently-banned IPs, large but non-security upgrade backlog)

Identical alerts are suppressed for `DEDUP_TTL` seconds (default 1h) via SHA1-keyed markers in `/var/lib/telegram-alerts/dedup/`, so a chronically full disk doesn't spam you every 5 minutes.

## 8) Daily heartbeat (recommended)

Set `HEARTBEAT_HOUR=09` in the env file. Once per day during that hour, if the cron tick runs, you'll receive a summary like:

```
💚 Daily heartbeat — your.server
up 12 days, 4 hours
Disk: 42% used (84G/200G)
Mem:  3.1G/7.7G used
Status: all checks green
```

Silence ≠ broken cron. Without this, a dead cron daemon would simply mean no alerts at all.

## 9) Tuning

All thresholds are env vars, so tuning never requires editing the script. Common adjustments:

- Noisy SSH brute-force on a public IP → lower `SSH_FAIL_THRESHOLD` for faster ban-flood detection, or rely on fail2ban and ignore.
- Tight VPS with bursty load → increase `CPU_LOAD_FACTOR` to 2.0 or 2.5.
- Very small disk → consider lowering `DISK_THRESHOLD` to 80% so you have warning time.
- High-traffic app server → raise `CONN_THRESHOLD` (default 2000 is low for production load balancers).
- Want only critical pages → set `DEDUP_TTL` very high and rely solely on changes.

## 10) Useful checks

```bash
# Service status snapshot
systemctl is-active docker dokploy nginx cron ssh fail2ban

# Recent alert script runs
sudo tail -n 50 /var/log/telegram-alerts.log

# Cron execution evidence
journalctl -u cron --since "1 hour ago" --no-pager | grep telegram-alerts

# Manually inspect what the script would alert on right now
sudo bash -x /usr/local/sbin/telegram-alerts.sh 2>&1 | less

# Reset dedup state (force all alerts to refire)
sudo rm -rf /var/lib/telegram-alerts/dedup

# Reset everything (next run re-initializes)
sudo rm -rf /var/lib/telegram-alerts
```

## 11) Troubleshooting

**No messages arrive** — verify the manual `curl` in step 6 returns `{"ok":true,...}`. Common causes: chat ID missing the leading `-` for groups, bot not started by your account, token typo.

**Same alert keeps firing every run** — `DEDUP_TTL` is too low, or the alert text varies slightly each run (e.g. includes a top-process PID that changes). Inspect `/var/lib/telegram-alerts/dedup/` modification times.

**Script silently does nothing** — it exits 0 in three cases: env file unreadable, lock held, first-run initialization. Check `ls -la /etc/telegram-alerts/env` and `lsof /var/lib/telegram-alerts/lock`.

**Telegram API rate limit** — bot accounts are limited to ~30 messages/sec, ~20 messages/min to the same chat. Long alert lists are batched into a single message; truncation kicks in above 4000 chars.

**Apt list warnings on Debian/Ubuntu** — harmless `WARNING: apt does not have a stable CLI interface` is suppressed via `2>/dev/null`. If you parse it elsewhere, switch to `apt-get -s upgrade`.

## 12) Hardening notes

- Run as root via `/etc/cron.d/`, not user crontab, so it can read `/var/log/auth.log`, run `journalctl`, and inspect Docker.
- Keep `/etc/telegram-alerts/env` at `0600` root:root; the bot token is a credential.
- Consider a dedicated Telegram channel (not your personal chat) so on-call rotation can be added later by inviting users.
- If you run multiple servers, set distinct `HEARTBEAT_HOUR` per host or use a separate chat per host so heartbeats don't all land in the same minute.