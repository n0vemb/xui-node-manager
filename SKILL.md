---
name: xui-node-manager
description: >-
  Create VLESS+Reality+TCP nodes on 3x-ui panels with SOCKS5 outbound binding.
  Use when user provides SOCKS5 exit info and specifies which 3x-ui server to target,
  or registers new 3x-ui servers. Triggers on giving socks5 ip:port:user:pass
  with a server name, or requests like create node, socks5 exit, 3x-ui, configure server.
---

# 3x-ui Node Manager

## Workflow

### 1. Server registration (one-time)

Edit `scripts/servers.yaml` using `scripts/servers.yaml.example` as template:

```yaml
proxy: socks5://127.0.0.1:10808

defaults:
  dest: 1.1.1.1:443
  server_names: [www.microsoft.com]
  port: random
  port_range: [10000, 60000]

servers:
  - name: server-1
    url: http://<ip>:<port>/<path>
    username: <user>
    password: <pass>
```

### 2. Create nodes (per-request)

User gives SOCKS5 exit + target server. Run:

```bash
pip install -r scripts/requirements.txt
python3 scripts/xui_batch.py --server <name|all> --socks5 <ip:port:user:pass>
```

### 3. Display results (MANDATORY)

After the script finishes, you MUST:

1. **Read the QR PNG file** whose path is printed in the output (look for `QR_PNG:` line)
2. **Display it inline** using the `read` tool — this renders the QR image directly in chat
3. **Print the vless:// URI** alongside it

Never just report the file path. Always show the QR image.

## Safety Rules

**NEVER delete existing inbounds without explicit user approval.**
The script creates new nodes on random ports — it does not need to delete anything.
If the user explicitly asks to delete a node, confirm which one before proceeding.
If port conflicts occur, ask the user before removing any inbound.

## Auto-generated settings

- Remark: today's date (YYYY-MM-DD)
- Port: random in [10000, 60000]
- Client tag: last 2 octets of SOCKS5 IP + date suffix
- Outbound tag: socks5-<ip>
- Reality keys: from panel API
