# 3x-ui 节点管理器

一键安装 3x-ui 面板 + 批量创建 VLESS+Reality+TCP 节点，自动绑定 SOCKS5 出口。

## 功能

| 功能 | 脚本 | 说明 |
|------|------|------|
| 安装面板 | `xui_install.sh` | SSH 远程安装 3x-ui，全自动 |
| 创建节点 | `xui_batch.py` | 创建 VLESS+Reality+TCP 入站 |
| 出口绑定 | 内置 | 自动创建 SOCKS5 出站 + 路由规则 |
| Xray 重启 | 内置 | 配置完成后自动重启 |

## 依赖

- `python3` ≥ 3.8
- `sshpass` + `expect`（安装面板用）
- 本地 SOCKS5 代理（如 v2rayN，访问面板用）

```bash
pip install -r scripts/requirements.txt
```

## 一、安装 3x-ui 面板

远程 SSH 到服务器，全自动安装 3x-ui 面板（自动应答所有交互提示）。

```bash
bash scripts/xui_install.sh <ip> <ssh端口> <用户名> <密码>
```

**示例：**

```bash
bash scripts/xui_install.sh 38.90.15.6 22 root mypassword
```

脚本会自动：
1. SSH 连接服务器
2. 执行 3x-ui 官方安装脚本
3. 自动以默认选项应答所有提示
4. 提取面板信息（URL / 用户名 / 密码 / 端口 / WebBasePath / API Token）
5. 检测 SSL 是否成功，失败则自动回退 HTTP

**安装完成后**，将输出信息填入 `scripts/servers.yaml`（见下一步）。

## 二、注册服务器

编辑 `scripts/servers.yaml`（参考 `servers.yaml.example`）：

```yaml
proxy: socks5://127.0.0.1:10808   # 访问面板的本地代理

defaults:
  dest: 1.1.1.1:443                # Reality 回落目标
  server_names: [www.microsoft.com] # Reality SNI
  port: random
  port_range: [10000, 60000]

servers:
  - name: server-1                 # 服务器别名
    url: http://<ip>:<port>/<path> # 面板地址
    username: <用户名>
    password: <密码>
```

## 三、创建节点

提供 SOCKS5 出口 + 目标服务器名：

```bash
python3 scripts/xui_batch.py --server <服务器名|all> --socks5 <ip:port:user:pass>
```

**示例：**

```bash
python3 scripts/xui_batch.py \
  --server server-1 \
  --socks5 204.0.23.109:9974:username:password
```

### 自动配置项

| 配置 | 规则 | 示例 |
|------|------|------|
| 备注 | 日期 + 出口 IP 末两段 | `2026-05-21-23.109` |
| 端口 | 随机 10000–60000 | `25827` |
| 客户端标识 | IP 末两段-日期 | `23.109-2026-05-21` |
| 出站标签 | `socks5-<IP>` | `socks5-204.0.23.109` |
| Reality dest | `1.1.1.1:443` | — |
| Reality SNI | `www.microsoft.com` | — |
| Reality 密钥 | 面板 API 自动生成 | — |

### 输出

- 终端 ASCII QR 码
- PNG 二维码文件
- `vless://` 直连链接

## 安全

- `servers.yaml` 含面板凭据，**已加入 .gitignore，勿提交公开**
- 脚本不会删除已有入站，仅创建新节点
- 删除操作需用户明确确认

## 项目结构

```
xui-node-manager/
├── README.md
├── SKILL.md                    # OpenClaw skill 描述
├── .gitignore
└── scripts/
    ├── xui_install.sh          # 面板安装
    ├── xui_batch.py            # 节点创建
    ├── requirements.txt
    ├── servers.yaml.example    # 配置模板
    └── servers.yaml            # 实际配置（不提交）
```
