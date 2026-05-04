# OpenClaw 版本信息仓库

[![Version](https://img.shields.io/badge/version-5.1.0-blue.svg)](https://github.com/jinge5998/openclaw-version)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/jinge5998/openclaw-version.svg)](https://github.com/jinge5998/openclaw-version/stargazers)

> OpenClaw U盘版启动器版本推送服务 - 实现自动检测更新功能

## 📋 项目简介

本仓库用于存储 OpenClaw U盘版的版本信息，配合启动器实现以下功能：

- ✅ 自动检测新版本
- ✅ 状态栏更新提示
- ✅ 定期后台检查
- ✅ 网络状态实时显示

## 🔗 快速链接

| 链接 | 说明 |
|------|------|
| [version.json](version.json) | 版本信息文件 |
| [SETUP.md](SETUP.md) | 快速设置指南 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 贡献指南 |

## 🚀 快速开始

### 方法一：直接使用（推荐）

启动器已预配置，无需额外设置即可自动检测更新。

### 方法二：Fork 后使用

1. Fork 本仓库
2. 修改启动器 `U-Claw-Launcher.ps1` 第 30-31 行：
```powershell
$script:NETWORK_VERSION_URL = "https://cdn.jsdelivr.net/gh/你的用户名/openclaw-version@main/version.json"
$script:NETWORK_VERSION_URL_BACKUP = "https://raw.githubusercontent.com/你的用户名/openclaw-version/main/version.json"
```

## 📝 版本文件格式

```json
{
  "version": "5.1.0",
  "releaseDate": "2026-05-05",
  "downloadUrl": "https://pan.baidu.com/s/分享链接",
  "downloadPassword": "提取密码",
  "minVersion": "4.0.0",
  "forceUpdate": false,
  "changelog": [
    { "type": "新增", "description": "功能描述" }
  ]
}
```

### 字段说明

| 字段 | 必填 | 说明 |
|------|:----:|------|
| version | ✅ | 版本号 |
| releaseDate | ✅ | 发布日期 |
| downloadUrl | ✅ | 下载链接 |
| downloadPassword | ❌ | 网盘提取密码 |
| minVersion | ❌ | 最低兼容版本 |
| forceUpdate | ❌ | 是否强制更新 |
| changelog | ✅ | 更新日志 |

## 🔗 CDN 访问地址

### jsdelivr（推荐，国内访问快）
```
https://cdn.jsdelivr.net/gh/jinge5998/openclaw-version@main/version.json
```

### GitHub Raw（备用）
```
https://raw.githubusercontent.com/jinge5998/openclaw-version/main/version.json
```

## 📊 更新历史

| 版本 | 日期 | 说明 |
|------|------|------|
| [5.1.0](version.json) | 2026-05-05 | 网络升级提醒功能 |
| 5.0.0 | 2026-05-03 | 初始版本 |

## 🛠️ 发布新版本

### 使用发布脚本
```powershell
.\发布新版本.ps1 -Version "5.2.0" -BaiduUrl "https://pan.baidu.com/s/xxx" -BaiduPassword "1234"
```

### 手动发布
1. 修改 `version.json`
2. 提交并推送：
```bash
git add version.json
git commit -m "发布 v5.2.0"
git push
```

## 📁 相关仓库

| 仓库 | 说明 |
|------|------|
| OpenClaw U盘版 | 便携式 AI 助手 |

## 📄 许可证

[MIT License](LICENSE)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

详见 [CONTRIBUTING.md](CONTRIBUTING.md)

---

**OpenClaw U盘版** - 便携式 AI 助手

⭐ 如果这个项目对你有帮助，请给一个 Star！
