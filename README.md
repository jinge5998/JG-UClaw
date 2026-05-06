# OpenClaw 版本信息仓库

<div align="center">

[![Version](https://img.shields.io/badge/version-5.1.0-blue.svg?style=for-the-badge)](https://github.com/jinge5998/openclaw-version)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=for-the-badge)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/jinge5998/openclaw-version.svg?style=for-the-badge)](https://github.com/jinge5998/openclaw-version/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/jinge5998/openclaw-version.svg?style=for-the-badge)](https://github.com/jinge5998/openclaw-version/issues)
[![GitHub Release](https://img.shields.io/github/release/jinge5998/openclaw-version.svg?style=for-the-badge)](https://github.com/jinge5998/openclaw-version/releases)

[![CI](https://img.shields.io/github/actions/workflow/status/jinge5998/openclaw-version/ci.yml?branch=main&label=CI&style=flat-square)](https://github.com/jinge5998/openclaw-version/actions/workflows/ci.yml)
[![CDN Status](https://img.shields.io/website?down_color=red&down_message=offline&label=jsdelivr%20CDN&up_color=green&up_message=online&url=https%3A%2F%2Fcdn.jsdelivr.net%2Fgh%2Fjinge5998%2Fopenclaw-version%40main%2Fversion.json&style=flat-square)](https://cdn.jsdelivr.net/gh/jinge5998/openclaw-version@main/version.json)
[![Last Updated](https://img.shields.io/github/last-commit/jinge5998/openclaw-version?style=flat-square)](https://github.com/jinge5998/openclaw-version/commits/main)

**OpenClaw U盘版启动器版本推送服务 - 实现自动检测更新功能**

[快速开始](#-快速开始) • [文档](#-文档) • [常见问题](FAQ.md) • [故障排除](TROUBLESHOOTING.md)

</div>

---

## 📋 项目简介

本仓库用于存储 OpenClaw U盘版的版本信息，配合启动器实现以下功能：

- ✅ **自动检测新版本** - 启动时自动检查更新
- ✅ **状态栏更新提示** - 非弹窗打扰模式
- ✅ **定期后台检查** - 可配置检查间隔
- ✅ **网络状态实时显示** - 在线/离线状态
- ✅ **双URL备份机制** - 提高可用性
- ✅ **GitHub版本推送** - 支持CDN加速

## 📊 当前版本

| 项目 | 信息 |
|------|------|
| **版本号** | `5.1.0` |
| **发布日期** | `2026-05-05` |
| **最低版本** | `4.0.0` |
| **许可证** | MIT |

### 📝 更新日志

- **新增**: 网络升级提醒功能，自动检测新版本
- **新增**: 状态栏更新提示，非弹窗打扰模式
- **新增**: 定期后台检查更新，可配置检查间隔
- **新增**: 网络状态实时显示（在线/离线）
- **新增**: 支持 GitHub 版本推送服务
- **新增**: 双 URL 备份机制，提高可用性
- **优化**: 升级按钮支持网络检查
- **优化**: 版本检查逻辑优化，支持本地回退
- **修复**: 修复网络请求超时处理

## 🔗 快速链接

| 链接 | 说明 |
|------|------|
| [version.json](version.json) | 版本信息文件 |
| [SETUP.md](SETUP.md) | 快速设置指南 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 贡献指南 |
| [FAQ.md](FAQ.md) | 常见问题 |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | 故障排除 |

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
  "fileName": "Upanban",
  "minVersion": "4.0.0",
  "forceUpdate": false,
  "changelog": [
    { "type": "新增", "description": "功能描述" }
  ],
  "checksum": "SHA256校验码（可选）",
  "size": 0,
  "requirements": {
    "os": "Windows 10/11",
    "diskSpace": "500MB"
  }
}
```

### 字段说明

| 字段 | 必填 | 说明 |
|------|:----:|------|
| `version` | ✅ | 版本号（语义化版本） |
| `releaseDate` | ✅ | 发布日期（YYYY-MM-DD） |
| `downloadUrl` | ✅ | 下载链接 |
| `downloadPassword` | ❌ | 网盘提取密码 |
| `fileName` | ❌ | 文件名称 |
| `minVersion` | ❌ | 最低兼容版本 |
| `forceUpdate` | ❌ | 是否强制更新 |
| `changelog` | ✅ | 更新日志数组 |
| `checksum` | ❌ | SHA256校验码 |
| `size` | ❌ | 文件大小（字节） |
| `requirements` | ❌ | 系统要求 |

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

### 自动发布（推荐）
创建 Git 标签自动触发发布：
```bash
git tag v5.2.0
git push origin v5.2.0
```

GitHub Actions 会自动：
- ✅ 验证版本信息
- ✅ 创建 GitHub Release
- ✅ 更新 latest 标签
- ✅ 生成发布说明

## 📁 相关仓库

| 仓库 | 说明 |
|------|------|
| OpenClaw U盘版 | 便携式 AI 助手 |

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

详见 [CONTRIBUTING.md](CONTRIBUTING.md)

### 贡献者

感谢所有贡献者！

[![Contributors](https://img.shields.io/github/contributors/jinge5998/openclaw-version.svg?style=flat-square)](https://github.com/jinge5998/openclaw-version/graphs/contributors)

## 📄 许可证

[MIT License](LICENSE)

## 📞 支持

- 📖 [文档](README.md)
- ❓ [常见问题](FAQ.md)
- 🔧 [故障排除](TROUBLESHOOTING.md)
- 🐛 [提交问题](https://github.com/jinge5998/openclaw-version/issues)

## ⭐ Star History

如果这个项目对你有帮助，请给一个 Star！

[![Star History Chart](https://api.star-history.com/svg?repos=jinge5998/openclaw-version&type=Date)](https://star-history.com/#jinge5998/openclaw-version&Date)

---

<div align="center">

**OpenClaw U盘版** - 便携式 AI 助手

Made with ❤️ by OpenClaw Team

© 2026 OpenClaw Team

</div>
