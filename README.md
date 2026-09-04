# mihomo-zimaos

Mihomo 的 ZimaOS 原生应用打包仓库，包含 MetaCubeXD Server/Agent WebUI、订阅管理、配置编辑、TUN 模式和 systemd 服务。

本仓库不维护 Mihomo 或 MetaCubeXD 源码。GitHub Actions 会从官方上游拉取固定版本并生成 ZimaOS 可安装的 `mihomo_zimaos.raw`。

本项目仅用于自行部署，不提交或上架 ZimaOS 应用商店。

## 功能

- 原生 systemd 服务，不依赖 Docker
- Mihomo TUN、规则模式、Fake-IP DNS
- MetaCubeXD Server/Agent WebUI
- 在 WebUI 中导入订阅 URL
- 在线编辑、校验和激活 Mihomo YAML
- 订阅定时更新和内核自动重启
- 自动生成 Clash API 与控制端随机密钥
- 首次启动时迁移 `/DATA/AppData/mihomo/config.yaml`
- 为 Docker 容器提供透明代理所需的 TUN/DNS 配置

## 默认端口

| 端口 | 用途 |
| --- | --- |
| `9091` | MetaCubeXD WebUI 与控制 API |
| `9090` | Mihomo External Controller |
| `7893` | HTTP/SOCKS Mixed Proxy |

WebUI 地址：`http://<ZimaOS-IP>:9091`

## 安装

从仓库的 `latest` Release 下载 `mihomo_zimaos.raw`，复制到 ZimaOS 后执行：

`zpkg install` 需要传入下载文件的完整路径，它会自行复制和挂载扩展：

```bash
sudo zpkg install "$(realpath mihomo_zimaos.raw)"
```

查看状态：

```bash
systemctl status mihomo-zimaos
journalctl -u mihomo-zimaos -f
```

卸载：

```bash
sudo zpkg remove mihomo_zimaos
```

## 从现有 Mihomo 服务迁移

如果设备上已经存在 `/DATA/AppData/mihomo/config.yaml`，应用首次启动时会将它复制为 MetaCubeXD 的初始 Profile。原文件不会删除或修改。

安装原生应用前应停止旧服务，避免 `7893` 和 `9090` 端口冲突：

```bash
sudo systemctl disable --now mihomo.service
sudo zpkg install /var/lib/extensions/mihomo_zimaos.raw
```

确认新服务正常后，再按需删除旧的 `/etc/systemd/system/mihomo.service` 和 `/DATA/AppData/mihomo`。

## WebUI 配置订阅

1. 打开 `http://<ZimaOS-IP>:9091`。
2. 默认 Mihomo 地址会自动填写为 `http://<ZimaOS-IP>:9090`。
3. 打开 Profiles，选择从 URL 导入。
4. 粘贴订阅 URL。
5. 检查 YAML 后点击 Activate。

应用内置 `ZimaOS system overlay`。它会为所有激活的基础 Profile 合并 TUN、DNS 劫持和 WebUI CORS 设置。为避免在尚未导入可用节点时影响整机网络，该 overlay 在干净安装时默认关闭。确认订阅通过 Mixed Proxy 可用后，再在 Profiles 中启用 overlay 并重新 Activate。若订阅本身已经完整管理这些字段，也可以保持关闭或编辑该 overlay。

## Docker 容器透明代理

Mihomo TUN 会代理容器发往公网的连接。为了避免路由器 DNS 污染，容器不要把私网网关 DNS 放在第一位：

```yaml
services:
  app:
    dns:
      - 1.1.1.1
      - 8.8.8.8
```

`1.1.1.1:53` 和 `8.8.8.8:53` 会被 Mihomo 的 `dns-hijack` 接管并返回 Fake-IP。局域网地址仍通过 `route-exclude-address` 直连。

## 数据目录

`.raw` 扩展以只读方式挂载。所有可写数据保存在：

```text
/var/lib/casaos/mihomo-zimaos/
├── active.yaml
├── active.yaml.bak
├── profiles/
└── secrets.env
```

备份该目录即可保存订阅、Profile、密钥和运行缓存。

## 本地构建

构建环境需要 Linux x86_64、Node.js/Corepack、Git、curl、xz、gzip 和 `mksquashfs`：

```bash
sudo apt-get install -y curl git xz-utils squashfs-tools
./scripts/build-raw.sh
```

输出文件：

```text
dist/mihomo_zimaos.raw
```

版本和校验值统一维护在 `versions.env`。GitHub Actions 会校验 MetaCubeXD commit、Mihomo 压缩包 SHA-256 和 Node.js 官方 SHA-256。

## 安全说明

- WebUI 会获得控制端 Token，因此只应暴露在可信局域网。
- Mihomo External Controller 使用随机 Secret，但仍建议通过防火墙限制 `9090`。
- Mixed Proxy 默认监听局域网，请勿直接暴露到公网。
- 不要把订阅 URL、节点信息、`secrets.env` 或实际 `config.yaml` 提交到仓库。

## 上游项目

- Mihomo: MetaCubeX/mihomo
- MetaCubeXD: MetaCubeX/metacubexd
- ZimaOS 原生模块格式参考 IceWhale 官方文档

具体许可证见 `THIRD_PARTY_NOTICES.md`。
