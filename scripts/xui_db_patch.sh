#!/bin/bash
# ============================================================
# 3x-ui DNS 防泄露 — DB 模板一次性补丁
# 用法: bash xui_db_patch.sh <ip> <ssh_port> <username> <password>
#
# 修补 3x-ui SQLite 数据库中的 xrayTemplateConfig，确保：
# - 所有 SOCKS5 出站 domainStrategy="AsIs"（域名不本地解析）
# - 路由 domainStrategy="IPIfNonMatch"
# - DNS 配置段存在（5 个带标签的 DNS 服务器）
#
# 只需每台服务器执行一次，永久生效，无需守护进程。
# ============================================================

set -euo pipefail

if [ $# -ne 4 ]; then
    echo "用法: $0 <ip> <ssh_port> <username> <password>"
    exit 1
fi

IP="$1"
PORT="$2"
USER="$3"
PASS="$4"

DB="${DB:-/etc/x-ui/x-ui.db}"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"

export SSHPASS="$PASS"

echo "🔧 连接 $USER@$IP:$PORT 修补 Xray DB 模板 ..."

# 生成临时 Python 补丁脚本
PATCH_SCRIPT=$(mktemp /tmp/xui_dns_patch_XXXXXX.py)
cat > "$PATCH_SCRIPT" << 'PYEOF'
import json, sqlite3, sys

DB = "/etc/x-ui/x-ui.db"

try:
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT value FROM settings WHERE key='xrayTemplateConfig'")
    row = c.fetchone()
    if not row:
        print("❌ xrayTemplateConfig 不存在")
        sys.exit(1)

    config = json.loads(row[0])
    changed = False

    # 1) DNS 配置段
    if not config.get('dns'):
        config['dns'] = {
            'servers': [
                {'address': '1.1.1.1', 'port': 53, 'tag': 'dns-cf'},
                {'address': '8.8.8.8', 'port': 53, 'tag': 'dns-google'},
                {'address': '9.9.9.9', 'port': 53, 'tag': 'dns-quad9'},
                {'address': '223.5.5.5', 'port': 53, 'tag': 'dns-ali', 'domains': ['geosite:cn']},
                {'address': 'localhost', 'port': 53, 'tag': 'dns-local', 'skipFallback': True},
            ]
        }
        changed = True
        print('  [+] DNS 配置段已添加')

    # 2) 所有 SOCKS5 出站 domainStrategy=AsIs
    for o in config.get('outbounds', []):
        if o.get('protocol') == 'socks' and o.get('domainStrategy') != 'AsIs':
            o['domainStrategy'] = 'AsIs'
            changed = True
            print(f'  [+] {o.get("tag","?")} → domainStrategy=AsIs')

    # 3) 路由 domainStrategy=IPIfNonMatch
    routing = config.setdefault('routing', {})
    if routing.get('domainStrategy') != 'IPIfNonMatch':
        routing['domainStrategy'] = 'IPIfNonMatch'
        changed = True
        print('  [+] routing.domainStrategy → IPIfNonMatch')

    if changed:
        c.execute(
            "UPDATE settings SET value=? WHERE key='xrayTemplateConfig'",
            (json.dumps(config, ensure_ascii=False),)
        )
        conn.commit()
        print('  ✅ DB 模板已更新并提交')
    else:
        print('  ℹ️  模板已是最新，无需修改')

    conn.close()
except Exception as e:
    print(f'❌ 出错: {e}')
    sys.exit(1)
PYEOF

# 上传补丁脚本到服务器
sshpass -e scp -P "$PORT" $SSH_OPTS "$PATCH_SCRIPT" "$USER@$IP:/tmp/xui_dns_patch.py" 2>/dev/null

# 在服务器上执行
sshpass -e ssh -p "$PORT" $SSH_OPTS "$USER@$IP" \
  "python3 /tmp/xui_dns_patch.py && rm -f /tmp/xui_dns_patch.py" 2>&1

rm -f "$PATCH_SCRIPT"

echo "✅ DNS 防泄露模板补丁完成"
