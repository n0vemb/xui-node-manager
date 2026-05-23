---
name: xui-node-manager
description: >-
  Install 3x-ui panels on servers via SSH, then create VLESS+Reality+TCP nodes
  with SOCKS5 outbound binding and DNS leak protection. Triggers on giving SSH
  or SOCKS5 info with a server name, or requests like install panel, create node,
  configure 3x-ui, DNS fix.
---

# 3x-ui Node Manager

## Workflows

### 0. Install 3x-ui panel (one-time per server)

User provides SSH login info. Run:

```bash
bash scripts/xui_install.sh <ip> <ssh_port> <username> <password>
```

What the script does:
1. SSH 登录到服务器
2. 运行 3x-ui 官方安装脚本
3. 全程自动按默认选项安装（自动回车确认）
4. 提取面板信息（URL、用户名、密码、端口、WebBasePath、API Token）
5. **自动修补 Xray DB 模板：DNS + domainStrategy=AsIs + IPIfNonMatch（DNS 防泄露）**

**After install, you MUST:**

1. Add the new panel to `scripts/servers.yaml` in the `servers:` list
   - 脚本自动检测 SSL 是否成功，失败则 URL 用 `http://` 而非 `https://`
2. Display the installation result to the user

No separate DNS fix step needed — it's built in.

### 1. Create nodes (per-request)

User gives SOCKS5 exit + target server. Run:

```bash
pip install -r scripts/requirements.txt
python3 scripts/xui_batch.py --server <name|all> --socks5 <ip:port:user:pass>
```

The script automatically:
- Adds `domainStrategy: "AsIs"` to all SOCKS5 outbounds in the running config
- Sets routing `domainStrategy: "IPIfNonMatch"`
- Adds DNS config if missing
- Restarts Xray after saving

DNS leak protection is built into every node creation — no extra steps.

### 2. Display results (MANDATORY)

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

- Remark: `YYYY-MM-DD-<IP末尾两段>`
- Port: random [10000, 60000]
- Client tag: `<IP末尾两段>-YYYY-MM-DD`
- Outbound tag: `socks5-<IP>`
- Reality keys: from panel API
- DNS: 5 upstream servers with tags, domainStrategy="AsIs" on all SOCKS outbounds
