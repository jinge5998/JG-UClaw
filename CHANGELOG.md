# 更新日志 (Changelog)

本项目的所有重要更改都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [5.2.0] - 2026-05-06

### 新增

- ✨ OpenClaw 核心升级到 2026.5.5 版本
- ✨ 模型配置同步更新，支持视觉/工具/思考能力
- ✨ qwen3.5:4b 支持 262K 上下文窗口
- ✨ gemma3:4b 支持 131K 上下文窗口和视觉
- ✨ qwen3:4b 支持 262K 上下文窗口和思考
- ✨ 完善 GitHub 同步更新功能
- ✨ 创建自动版本发布脚本 (publish-version.ps1)
- ✨ 创建版本检查脚本 (check-updates.ps1)

### 优化

- ⚡ 模型参数与本地 Ollama 实际配置同步
- ⚡ 修复 update-config.json URL 配置
- ⚡ 完善版本更新工作流程

### 文档

- 📝 更新 README.md 包含完整模型列表
- 📝 添加版本发布脚本使用说明
- 📝 更新版本命名规范

## [5.1.0] - 2026-05-05

### 新增

- ✨ 网络升级提醒功能，自动检测新版本
- ✨ 状态栏更新提示，非弹窗打扰模式
- ✨ 定期后台检查更新，可配置检查间隔
- ✨ 网络状态实时显示（在线/离线）
- ✨ 支持 GitHub 版本推送服务
- ✨ 双 URL 备份机制，提高可用性

### 优化

- ⚡ 升级按钮支持网络检查
- ⚡ 版本检查逻辑优化，支持本地回退
- ⚡ CDN 加速访问，国内用户访问更快

### 修复

- 🐛 修复网络请求超时处理
- 🐛 修复版本比较逻辑错误
- 🐛 修复离线模式下的异常处理

### 文档

- 📝 新增 FAQ.md 常见问题文档
- 📝 新增 TROUBLESHOOTING.md 故障排除指南
- 📝 优化 README.md 添加更多徽章和说明

### CI/CD

- 👷 新增 GitHub Actions 自动发布工作流
- 👷 新增版本验证工作流
- 👷 新增 CDN 状态检查

## [5.0.0] - 2026-05-03

### 新增

- ✨ OpenClaw 核心升级到 2026.5.2 版本
- ✨ 一键备份功能，支持备份技能、配置和核心文件
- ✨ 技能管理窗口，查看已安装技能详情
- ✨ 豆包大模型支持（Pro 256K、Lite 128K）
- ✨ 智谱GLM-5.0/5.1/5V模型支持
- ✨ 模型列表扩展至85+模型

### 优化

- ⚡ 修复编码问题导致的启动失败
- ⚡ 修复环境支持从网盘下载完整修复包
- ⚡ 版本更新提示改为状态栏显示

### 修复

- 🐛 修复启动器在某些系统上的兼容性问题
- 🐛 修复模型切换后的配置保存问题
- 🐛 修复备份功能中的文件权限问题

### 文档

- 📝 完善项目文档结构
- 📝 新增贡献指南
- 📝 新增安全政策

## [4.0.0] - 2026-04-15

### 新增

- ✨ 全新的启动器界面设计
- ✨ 支持 35+ 云端 AI 模型
- ✨ 自定义模型厂商功能
- ✨ 一键更新模型列表
- ✨ 一机一码授权系统

### 优化

- ⚡ 启动速度优化
- ⚡ 内存占用优化
- ⚡ 网络请求优化

### 修复

- 🐛 修复多个已知问题

## 版本命名规范

本项目遵循 [语义化版本 2.0.0](https://semver.org/lang/zh-CN/)：

- **主版本号（MAJOR）**：不兼容的 API 修改
- **次版本号（MINOR）**：向下兼容的功能性新增
- **修订号（PATCH）**：向下兼容的问题修正

### 更新类型说明

| 图标 | 类型 | 说明 |
|:----:|------|------|
| ✨ | 新增 | 新功能 |
| ⚡ | 优化 | 性能优化或改进 |
| 🐛 | 修复 | Bug 修复 |
| 📝 | 文档 | 文档更新 |
| 👷 | CI/CD | 持续集成/部署相关 |
| 🔒 | 安全 | 安全相关更新 |
| 🎨 | 样式 | 代码格式调整 |
| ♻️ | 重构 | 代码重构 |
| ✅ | 测试 | 测试相关 |
| 🗑️ | 移除 | 移除功能或文件 |

## 版本发布流程

### 方式一：使用脚本发布（推荐）

```powershell
# 1. 发布新版本
.\publish-version.ps1 -Version "5.3.0" -CoreVersion "2026.6.1" -Message "新功能说明"

# 2. 推送到 GitHub
.\publish-version.ps1 -Version "5.3.0" -CoreVersion "2026.6.1" -Message "新功能说明" -AutoPush
```

### 方式二：手动发布

1. 修改 `version.json` 中的版本信息
2. 更新 CHANGELOG.md
3. 提交并推送
4. 创建 Git Tag

```bash
git tag v5.3.0
git push origin main
git push origin v5.3.0
```

### 方式三：GitHub Actions 自动发布

1. 前往 GitHub Actions 页面
2. 选择 🚀 Auto Release workflow
3. 点击 Run workflow
4. 输入版本号

## 版本检查

```powershell
# 检查更新
.\check-updates.ps1

# 详细输出
.\check-updates.ps1 -Verbose

# JSON 格式输出
.\check-updates.ps1 -Json
```

## 支持的版本

| 版本 | 支持状态 | 说明 |
|------|:--------:|------|
| 5.2.x | ✅ 支持 | 当前稳定版本 |
| 5.1.x | ⚠️ 仅安全更新 | 维护模式 |
| 5.0.x | ⚠️ 仅安全更新 | 维护模式 |
| < 5.0 | ❌ 不支持 | 已停止维护 |

## 贡献

如果您想为本项目做出贡献，请查看 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

[未发布]: https://github.com/jinge5998/JG-UClaw/compare/v5.2.0...HEAD
[5.2.0]: https://github.com/jinge5998/JG-UClaw/compare/v5.1.0...v5.2.0
[5.1.0]: https://github.com/jinge5998/JG-UClaw/compare/v5.0.0...v5.1.0
[5.0.0]: https://github.com/jinge5998/JG-UClaw/compare/v4.0.0...v5.0.0
[4.0.0]: https://github.com/jinge5998/JG-UClaw/releases/tag/v4.0.0

---

© 2026 OpenClaw Team
