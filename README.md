# OpenClaw 版本信息仓库

用于 OpenClaw U盘版启动器的版本推送服务。

## 📋 使用说明

### 版本文件格式

`version.json` 文件格式如下：

```json
{
  "version": "5.1.0",
  "releaseDate": "2026-05-05",
  "downloadUrl": "https://pan.baidu.com/s/xxxxx",
  "downloadPassword": "xxxx",
  "minVersion": "4.0.0",
  "forceUpdate": false,
  "changelog": [
    { "type": "新增", "description": "功能描述" }
  ],
  "checksum": "",
  "size": 0
}
```

### 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| version | string | ✅ | 版本号，如 "5.1.0" |
| releaseDate | string | ✅ | 发布日期，格式 "YYYY-MM-DD" |
| downloadUrl | string | ✅ | 下载链接（百度网盘/迅雷网盘等） |
| downloadPassword | string | ❌ | 网盘提取密码 |
| minVersion | string | ❌ | 最低兼容版本 |
| forceUpdate | boolean | ❌ | 是否强制更新 |
| changelog | array | ✅ | 更新日志列表 |
| checksum | string | ❌ | 文件校验码（SHA256） |
| size | number | ❌ | 文件大小（字节） |

### 更新日志格式

```json
{
  "type": "新增|修复|优化|移除",
  "description": "功能描述"
}
```

## 🚀 发布新版本流程

### 1. 准备安装包
- 将新版本安装包上传到网盘（百度网盘/迅雷网盘）
- 记录分享链接和提取密码

### 2. 更新版本文件
修改 `version.json` 文件：

```json
{
  "version": "5.2.0",
  "releaseDate": "2026-05-10",
  "downloadUrl": "https://pan.baidu.com/s/新的分享链接",
  "downloadPassword": "新密码",
  "changelog": [
    { "type": "新增", "description": "新功能1" },
    { "type": "修复", "description": "修复问题1" }
  ]
}
```

### 3. 提交更改
```bash
git add version.json
git commit -m "发布 v5.2.0"
git push origin main
```

### 4. 验证更新
- CDN 缓存会在几分钟内刷新
- 启动器会在下次检查时发现新版本

## 🔧 客户端配置

### 启动器配置
在 `U-Claw-Launcher.ps1` 中配置版本检查 URL：

```powershell
$script:NETWORK_VERSION_URL = "https://cdn.jsdelivr.net/gh/你的用户名/openclaw-version@main/version.json"
$script:NETWORK_VERSION_URL_BACKUP = "https://raw.githubusercontent.com/你的用户名/openclaw-version/main/version.json"
```

### 本地配置文件
客户端配置存储在 `data/.openclaw/update-config.json`：

```json
{
  "versionUrl": "",
  "checkInterval": 24,
  "lastCheck": 0,
  "skippedVersions": [],
  "autoCheck": true
}
```

## 📡 CDN 加速

### jsdelivr CDN
- 主链接：`https://cdn.jsdelivr.net/gh/用户名/仓库名@分支/文件路径`
- 缓存时间：约 12 小时
- 强制刷新：在 URL 后添加 `?v=版本号`

### 示例 URL
```
https://cdn.jsdelivr.net/gh/your-username/openclaw-version@main/version.json
```

## 🔒 安全建议

1. **不要在版本文件中存储敏感信息**
2. **使用 HTTPS 协议**
3. **定期检查下载链接有效性**
4. **建议添加文件校验码**

## 📝 更新历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 5.1.0 | 2026-05-05 | 新增网络升级提醒功能 |
| 5.0.0 | 2026-05-03 | 初始版本 |

---

**OpenClaw U盘版** - 便携式 AI 助手
