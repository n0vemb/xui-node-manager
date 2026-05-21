# 3x-ui 节点管理器

基于 3x-ui 面板 API 的批量 VLESS+Reality+TCP 节点管理工具，自动绑定 SOCKS5 出口。

## 功能

- 接收 SOCKS5 出口 (`ip:port:user:pass`) + 目标服务器名
- 自动创建 VLESS+Reality+TCP 入站
- 自动生成 Reality 密钥（通过面板 API）
- 自动绑定 SOCKS5 出站 + 路由规则
- 自动重启 Xray 使路由生效
- 生成 QR 码 + `vless://` 链接

## 配置

复制 `scripts/servers.yaml.example` 为 `scripts/servers.yaml`，填写面板信息：

```yaml
proxy: socks5://127.0.0.1:10808   # 本地代理（访问面板用）

defaults:
  dest: 1.1.1.1:443
  server_names: [www.microsoft.com]
  port: random
  port_range: [10000, 60000]

servers:
  - name: server-1
    url: http://<ip>:<port>/<path>
    username: <用户名>
    password: <密码>
```

## 使用

```bash
pip install -r scripts/requirements.txt
python3 scripts/xui_batch.py --server <服务器名|all> --socks5 <ip:port:user:pass>
```

### 示例

```bash
python3 scripts/xui_batch.py \
  --server server-1 \
  --socks5 204.0.23.109:9974:username:password
```

## 自动配置项

| 配置 | 规则 |
|------|------|
| 备注 | 当天日期 + 出口 IP 末两段（如 `2026-05-21-23.109`） |
| 端口 | 随机 10000–60000 |
| 客户端标识 | `IP末两段-日期`（如 `23.109-2026-05-21`） |
| 出站标签 | `socks5-<IP>`（如 `socks5-204.0.23.109`） |
| Reality 密钥 | 面板 API 自动生成 |

## 安全

- 服务器配置文件 `servers.yaml` 含面板凭据，**勿提交到公开仓库**
- 脚本不会删除已有入站，仅创建新节点

## 依赖

- Python 3.8+
- 3x-ui 面板（支持 API）
- 本地 SOCKS5 代理（如 v2rayN）
