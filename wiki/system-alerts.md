
# System Alerts to Telegram

This guide sets up a lightweight VPS monitoring job that sends Telegram alerts for:
- disk usage
- RAM/CPU usage
- service outages (docker, dokploy, nginx, cron)
- Dokploy deploy failures
- system update / security events

## 1) Create a Telegram bot
1. Open Telegram and start a chat with **BotFather**.
2. Create a new bot and copy the **bot token**.
3. Send a message to the bot from your account.
4. Get your **chat ID** (for example with a Telegram helper bot or by checking the update payload).

## 2) Create the environment file
Create a secure file with your Telegram credentials:

```bash
sudo install -d -m 700 /etc/telegram-alerts
sudo nano /etc/telegram-alerts/env
```

Add:

```bash
TELEGRAM_TOKEN=YOUR_BOT_TOKEN
TELEGRAM_CHAT_ID=YOUR_CHAT_ID
```

Lock it down:

```bash
sudo chmod 600 /etc/telegram-alerts/env
```

## 3) Create the alert script
Create the script:

```bash
sudo nano /usr/local/bin/system-alerts.sh
```

Paste this:

```bash
#!/usr/bin/env bash
set -u

ENV_FILE=/etc/telegram-alerts/env
STATE_DIR=/var/lib/telegram-alerts
STATE_FILE="$STATE_DIR/last_run"
MARK_FILE="$STATE_DIR/marker"
LOCK_FILE="$STATE_DIR/lock"

[ -r "$ENV_FILE" ] || exit 0
source "$ENV_FILE"

mkdir -p "$STATE_DIR"
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

now=$(date +%s)
if [ ! -f "$STATE_FILE" ]; then
  printf '%s' "$now" > "$STATE_FILE"
  touch -d "@$now" "$MARK_FILE"
  exit 0
fi

last=$(cat "$STATE_FILE" 2>/dev/null || echo "$now")
[ "$last" -gt 0 ] 2>/dev/null || last="$now"
touch -d "@$last" "$MARK_FILE"

alerts=()

send() {
  local msg="$1"
  [ -n "$msg" ] || return 0
  curl -fsS -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    --data-urlencode text="$msg" >/dev/null 2>&1 || true
}

add_alert() { alerts+=("$1"); }

# Disk usage
while IFS= read -r line; do
  add_alert "Disk usage high: $line"
done < <(
  df -P -x tmpfs -x devtmpfs | awk 'NR>1 && $5+0>=85 {gsub("%","",$5); print $0}'
)

# Memory / CPU
mem=$(free | awk '/Mem:/ {printf("%.0f", ($3/$2)*100)}')
[ -n "${mem:-}" ] && [ "$mem" -ge 85 ] 2>/dev/null && add_alert "Memory usage high: ${mem}%"
load1=$(awk '{print $1}' /proc/loadavg)
cores=$(nproc)
awk -v l="$load1" -v c="$cores" 'BEGIN{exit !(l > c*1.5)}' && add_alert "CPU/load high: load1=${load1}, cores=${cores}"

# Services
for svc in docker dokploy nginx cron; do
  systemctl is-active --quiet "$svc" 2>/dev/null || add_alert "Service down: $svc"
done

# Dokploy deploy failures
if [ -d /etc/dokploy/logs ]; then
  while IFS= read -r f; do
    if grep -Eaiq '(unauthorized|error|failed|panic|exception|❌|FATAL)' "$f"; then
      add_alert "Deploy/log failure detected: $(basename "$f")"
    fi
  done < <(find /etc/dokploy/logs -type f -newer "$MARK_FILE" 2>/dev/null | sort)
fi

# System updates / security events
if [ -d /var/log/unattended-upgrades ] || [ -d /var/log/apt ]; then
  while IFS= read -r f; do
    if grep -Eaiq '(security|upgrade|upgraded|install|remove|failed|error)' "$f"; then
      add_alert "System update/security event: $(basename "$f")"
    fi
  done < <(find /var/log/unattended-upgrades /var/log/apt -type f -newer "$MARK_FILE" 2>/dev/null | sort)
fi

if [ "${#alerts[@]}" -gt 0 ]; then
  host=$(hostname -f 2>/dev/null || hostname)
  msg="[${host}]
$(printf '%s
' "${alerts[@]}" | sed 's/^/- /')"
  send "$msg"
fi

printf '%s' "$now" > "$STATE_FILE"
touch -d "@$now" "$MARK_FILE"
```

Make it executable:

```bash
sudo chmod 700 /usr/local/bin/system-alerts.sh
```

## 4) Add the cron job
Run it every 5 minutes:

```bash
printf '%s
' '*/5 * * * * /usr/local/bin/system-alerts.sh' | crontab -
```

Verify:

```bash
crontab -l
```

## 5) Initialize the state files
Run the script once so it creates its state and starts clean:

```bash
/usr/local/bin/system-alerts.sh
```

## 6) Test the Telegram alert
Send a manual test message:

```bash
source /etc/telegram-alerts/env
host=$(hostname -f 2>/dev/null || hostname)
curl -fsS -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  -d chat_id="$TELEGRAM_CHAT_ID" \
  --data-urlencode text="[${host}]
- Test alert: Telegram notifications are working."
```

## 7) Optional tuning
You can adjust these values in the script:
- disk warning threshold: `85%`
- memory warning threshold: `85%`
- CPU/load threshold: `load1 > cores * 1.5`
- cron interval: `*/5 * * * *`

## 8) Useful checks
```bash
systemctl is-active docker dokploy nginx cron
journalctl -u cron -n 50 --no-pager
```