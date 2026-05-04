# OpenClaw 版本信息仓库

[![Version](https://img.shields.io/badge/version-5.1.0-blue.svg)](https://github.com/your-username/openclaw-version)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> 用于 OpenClaw U盘版启动器的版本推送服务

## 📋 快速链接

| 链接 | 说明 |
|------|------|
| [version.json](version.json) | 版本信息文件 |
| [SETUP.md](SETUP.md) | 快速设置指南 |
| [发布指南](../发布指南.md) | 完整发布文档 |

## 🚀 快速开始

### 1. Fork 本仓库

### 2. 修改启动器配置

编辑 `U-Claw-Launcher.ps1` 第 30-31 行：

```powershell
$script:NETWORK_VERSION_URL = "https://cdn.jsdelivr.net/gh/你的用户名/openclaw-version@main/version.json"
$script:NETWORK_VERSION_URL_BACKUP = "https://raw.githubusercontent.com/你的用户名/openclaw-version/main/version.json"
```

### 3. 发布新版本

修改 `version.json` 并推送即可！

## 📝 版本文件格式

```json
{
  "version": "5.1.0",
  "releaseDate": "2026-05-05",
  "downloadUrl": "https://pan.baidu.com/s/分享链接",
  "downloadPassword": "提取密码",
  "changelog": [
    { "type": "新增", "description": "功能描述" }
  ]
}
```

## 🔗 CDN 访问

### jsdelivr（推荐）
```
https://cdn.jsdelivr.net/gh/用户名/openclaw-version@main/version.json
```

### GitHub Raw
```
https://raw.githubusercontent.com/用户名/openclaw-version/main/version.json
```

## 📊 更新历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 5.1.0 | 2026-05-05 | 网络升级提醒功能 |
| 5.0.0 | 2026-05-03 | 初始版本 |

## 📄 许可证

[MIT License](LICENSE)

---

**OpenClaw U盘版** - 便携式 AI 助手
