# OpenClaw UClaw 自动升级系统

<div align="center">

[![Version](https://img.shields.io/badge/version-5.1.0-blue.svg)](https://github.com/jinge5998/JG-UClaw)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Auto Update](https://img.shields.io/badge/auto--update-enabled-brightgreen.svg?style=flat-square)](https://github.com/jinge5998/JG-UClaw)

**OpenClaw UClaw 便携版 - 自动升级版本仓库**

</div>

---

## 📋 项目简介

本仓库用于存储 OpenClaw UClaw 便携版的版本信息和升级文件，支持自动检测更新和一键升级功能。

## 🔄 自动同步更新功能

### 工作原理

1. **版本检测**：启动器自动从本仓库获取最新版本信息
2. **智能比较**：对比本地版本和网络版本，判断是否需要升级
3. **状态提示**：在状态栏显示更新提示（非弹窗打扰）
4. **一键升级**：用户确认后自动下载并安装更新

### CDN 访问地址

- **jsdelivr CDN（推荐）**：
  ```
  https://cdn.jsdelivr.net/gh/jinge5998/JG-UClaw@main/version.json
  ```

- **GitHub Raw（备用）**：
  ```
  https://raw.githubusercontent.com/jinge5998/JG-UClaw/main/version.json
  ```

## 📦 版本文件说明

### version.json

核心版本配置文件，包含以下字段：

```json
{
  "version": "5.1.0",           // 当前版本号
  "releaseDate": "2026-05-05",  // 发布日期
  "downloadUrl": "百度网盘链接", // 下载地址
  "downloadPassword": "提取码",   // 网盘提取码
  "minVersion": "4.0.0",        // 最低兼容版本
  "forceUpdate": false,         // 是否强制更新
  "launcherVersion": "5.1.0",   // 启动器版本
  "coreVersion": "2026.5.2",    // 核心版本
  "urls": {
    "primary": "主CDN地址",
    "backup": "备用地址"
  }
}
```

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/jinge5998/JG-UClaw.git
cd JG-UClaw
```

### 2. 查看版本信息

直接访问：
```
https://cdn.jsdelivr.net/gh/jinge5998/JG-UClaw@main/version.json
```

### 3. 更新版本

修改 `version.json` 文件，然后提交推送即可：

```bash
git add version.json
git commit -m "发布 v5.2.0"
git push
```

## 🔧 发布新版本

### 方式一：手动更新

1. 修改 `version.json` 中的版本信息
2. 更新下载链接和提取码
3. 提交并推送到 GitHub

### 方式二：自动发布（推荐）

使用 GitHub Actions 自动发布：

1. 创建 Git Tag：
   ```bash
   git tag v5.2.0
   git push origin v5.2.0
   ```

2. GitHub Actions 自动：
   - ✅ 验证版本信息
   - ✅ 创建 Release
   - ✅ 更新文档

## 📊 当前版本状态

| 项目 | 值 |
|------|-----|
| **启动器版本** | 5.1.0 |
| **核心版本** | 2026.5.2 |
| **发布日期** | 2026-05-05 |
| **最低兼容** | 4.0.0 |

## 🔗 相关链接

- [百度网盘下载](https://pan.baidu.com/s/1zgtbt1tDRTFGhCnKpRXmAw)
- [提取码] 6hfe

## 📝 目录结构

```
JG-UClaw/
├── version.json           # 核心版本配置文件
├── README.md             # 本说明文档
├── LICENSE              # MIT 许可证
└── .github/
    └── workflows/        # GitHub Actions 工作流
        └── release.yml  # 自动发布工作流
```

## 🔒 安全特性

- ✅ 设备激活验证
- ✅ 升级前自动备份
- ✅ 失败自动回滚
- ✅ 文件完整性校验

## 📞 支持

- 🐛 [提交问题](https://github.com/jinge5998/JG-UClaw/issues)
- 📖 [查看文档](README.md)
- 🔧 [故障排除](TROUBLESHOOTING.md)

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

<div align="center">

**OpenClaw UClaw** - 便携式 AI 助手

Made with ❤️ by OpenClaw Team

© 2026 OpenClaw Team

</div>
