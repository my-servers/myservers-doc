# MyServers 文档

MyServers 是一个面向 NAS 和家庭服务器场景的服务端管理工具，可配合 iOS 客户端完成设备接入、容器管理、下载管理、日志查看和远程操作。

## 快速安装

推荐直接使用安装脚本：

```bash
curl -fsSL https://api.myservers.plus/install -o install.sh && chmod +x install.sh && ./install.sh
```

安装向导会自动检测当前环境，并引导你选择：

- `npm` 安装：推荐，兼容性最好，后续升级也更直接
- `Docker` 安装：支持 Linux 和 macOS，Linux 兼容性最佳

## 安装前准备

建议提前确认以下环境：

- `Node.js` 和 `npm`：如果计划使用 `npm` 安装
- `Docker`：如果计划使用 `Docker` 安装
- 局域网网络可用：方便 iPhone 与服务端配对

如果你是 Debian / Ubuntu 用户，建议先确认系统已安装 `bash`：

```bash
bash --version
```

## 安装方式

### 方式一：npm 安装

适合绝大多数用户，配置简单，后续升级方便。

```bash
npm install -g @my-servers/myservers@latest --registry=https://registry.npmjs.org
```

安装完成后，可以按安装向导提示启动，或者手动启动：

```bash
myservers -op=server -k 你的32位密钥
```

查看配对配置：

```bash
myservers -op=show_config -k 你的32位密钥
```

### 方式二：Docker 安装

支持 Linux 和 macOS。Linux 下会使用 host 网络模式；macOS 下会自动切换为 Docker Desktop 兼容的端口映射模式。

如果你已经明确自己的部署方式，也可以直接参考向导中的 `docker run` 命令执行。

## 首次使用

服务端安装完成后，建议按这个顺序操作：

1. 启动 MyServers 服务端
2. 执行 `show_config` 查看当前配对信息
3. 在 iPhone 上打开 MyServers App
4. 按提示输入配对码或扫描二维码完成连接

配对完成后，就可以在 App 里管理服务器、容器、下载任务和日志。

## 常用命令

### 后台启动

安装向导会给出后台启动命令。若你选择稍后手动执行，可直接使用向导里显示的命令。

### 查看配置

```bash
myservers -op=show_config -k 你的32位密钥
```

### 查看日志

```bash
tail -f ~/.myservers/logs/server.log
```

### 停止服务

```bash
pkill myservers
```

## 升级

如果你使用的是 `npm` 安装，可以直接执行：

```bash
npm install -g @my-servers/myservers@latest --registry=https://registry.npmjs.org
```

然后重新启动服务即可。

## 常见问题

### 1. 安装脚本执行报错

建议先检查脚本头部和 bash 是否正常：

```bash
head -20 install.sh
bash --version
```

如果 npm 报 `No matching version found for @my-servers/myservers@latest`，通常是当前 npm 镜像源没有同步到最新版本。请使用官方 npm 源重试：

```bash
npm install -g @my-servers/myservers@latest --registry=https://registry.npmjs.org
```

### 2. App 无法发现服务端

请确认：

- iPhone 和服务端在同一局域网
- 服务端已经成功启动
- 防火墙没有拦截对应端口
- 你使用的是 `show_config` 输出的最新配置信息

### 3. Docker 模式不可用

当前安装向导中的 Docker 方案已支持 macOS，但由于 Docker Desktop 与 Linux 内核能力不同，部分宿主机系统信息能力会受限；若你更看重兼容性，macOS 和 Windows 仍更推荐走 `npm` 安装。

## 仓库内容

- `install.sh`：MyServers 官方安装脚本
- `README.md`：面向用户的安装和使用说明
