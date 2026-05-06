# 🔧 故障排除指南

本文档提供 OpenClaw U盘版常见问题的诊断和解决方法。

## 📋 目录

- [启动问题](#启动问题)
- [网络问题](#网络问题)
- [升级问题](#升级问题)
- [模型问题](#模型问题)
- [授权问题](#授权问题)
- [性能问题](#性能问题)
- [数据问题](#数据问题)

## 启动问题

### ❌ 问题：启动时提示"无法找到 Node.js"

**诊断步骤：**
1. 检查 `app/runtime/node-win-x64/node.exe` 是否存在
2. 检查文件是否被杀毒软件删除
3. 检查路径是否包含特殊字符

**解决方案：**
```powershell
# 方案1：使用修复功能
点击启动器中的"修复环境"按钮

# 方案2：手动下载 Node.js
1. 访问 https://nodejs.org/dist/v22.22.1/
2. 下载 node-v22.22.1-win-x64.zip
3. 解压到 app/runtime/node-win-x64/

# 方案3：检查杀毒软件
将 OpenClaw 目录添加到杀毒软件白名单
```

### ❌ 问题：启动时出现乱码

**诊断步骤：**
1. 检查系统区域设置
2. 检查 PowerShell 编码设置
3. 检查文件编码格式

**解决方案：**
```powershell
# 方案1：设置 PowerShell 编码
chcp 65001

# 方案2：修改系统区域设置
控制面板 → 区域 → 管理 → 更改系统区域设置
勾选"Beta版：使用 Unicode UTF-8 提供全球语言支持"

# 方案3：解除文件锁定
右键点击 U-Claw-Launcher.ps1 → 属性 → 解除锁定
```

### ❌ 问题：启动时闪退或无响应

**诊断步骤：**
1. 查看错误日志
2. 检查是否有进程冲突
3. 检查系统权限

**解决方案：**
```powershell
# 方案1：查看详细错误
在 PowerShell 中运行：
.\U-Claw-Launcher.ps1

# 方案2：检查进程冲突
Get-Process | Where-Object {$_.ProcessName -like "*node*"}

# 方案3：以管理员身份运行
右键点击 → 以管理员身份运行
```

## 网络问题

### ❌ 问题：无法检测到网络连接

**诊断步骤：**
1. 测试网络连通性
2. 检查防火墙设置
3. 检查代理配置

**解决方案：**
```powershell
# 方案1：测试网络连接
Test-Connection www.baidu.com

# 方案2：检查防火墙
netsh advfirewall show allprofiles

# 方案3：配置代理
# 设置系统代理或使用环境变量
$env:HTTP_PROXY = "http://proxy-server:port"
$env:HTTPS_PROXY = "http://proxy-server:port"
```

### ❌ 问题：版本检查超时

**诊断步骤：**
1. 测试 CDN 访问
2. 检查 DNS 解析
3. 检查网络速度

**解决方案：**
```powershell
# 方案1：测试 CDN 访问
Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/gh/jinge5998/openclaw-version@main/version.json"

# 方案2：更换 DNS
# 设置 DNS 为 8.8.8.8 或 114.114.114.114

# 方案3：使用本地版本信息
# 系统会自动使用本地 remote-version.json 作为备用
```

### ❌ 问题：无法访问 GitHub

**诊断步骤：**
1. 测试 GitHub 访问
2. 检查网络限制
3. 检查 DNS 污染

**解决方案：**
```powershell
# 方案1：使用 CDN 加速
# jsdelivr CDN 可以加速访问 GitHub 文件

# 方案2：修改 hosts 文件
# 添加 GitHub IP 到 hosts 文件

# 方案3：使用代理或 VPN
# 配置系统代理或使用 VPN
```

## 升级问题

### ❌ 问题：升级提示"设备未激活"

**诊断步骤：**
1. 检查授权文件是否存在
2. 检查授权是否过期
3. 检查硬件ID是否匹配

**解决方案：**
```powershell
# 方案1：检查授权文件
Test-Path "data\.license"

# 方案2：重新激活
点击"激活授权"按钮，输入有效授权码

# 方案3：检查授权状态
# 查看授权信息中的到期时间和设备信息
```

### ❌ 问题：升级下载失败

**诊断步骤：**
1. 检查网络连接
2. 检查下载链接是否有效
3. 检查磁盘空间

**解决方案：**
```powershell
# 方案1：检查磁盘空间
Get-PSDrive -PSProvider FileSystem

# 方案2：手动下载
# 访问版本信息中的 downloadUrl 手动下载

# 方案3：使用备用下载源
# 系统会自动尝试备用下载源
```

### ❌ 问题：升级后无法启动

**诊断步骤：**
1. 检查备份文件
2. 检查文件完整性
3. 查看错误日志

**解决方案：**
```powershell
# 方案1：从备份恢复
# 从 data/backup 目录恢复之前的版本

# 方案2：重新下载
# 删除当前版本，重新下载完整包

# 方案3：检查文件完整性
# 对比文件的 SHA256 校验值
```

## 模型问题

### ❌ 问题：模型列表为空

**诊断步骤：**
1. 检查配置文件
2. 检查网络连接
3. 检查 API Key 配置

**解决方案：**
```powershell
# 方案1：检查配置文件
Get-Content "data/.openclaw/models-config.json"

# 方案2：重新加载模型
点击"切换 AI 模型" → "刷新模型列表"

# 方案3：检查本地模型
# 如果使用 Ollama，检查 Ollama 服务是否运行
```

### ❌ 问题：模型 API 调用失败

**诊断步骤：**
1. 检查 API Key 是否正确
2. 检查 API 地址是否可访问
3. 检查配额是否充足

**解决方案：**
```powershell
# 方案1：测试 API 连接
# 使用 curl 或 Postman 测试 API

# 方案2：更新 API Key
# 重新配置模型的 API Key

# 方案3：检查账户余额
# 登录模型提供商控制台查看配额
```

### ❌ 问题：自定义模型无法使用

**诊断步骤：**
1. 检查模型配置格式
2. 检查 API 兼容性
3. 检查网络访问

**解决方案：**
```powershell
# 方案1：验证配置格式
# 确保配置符合 OpenAI API 格式

# 方案2：测试 API 端点
# 使用 curl 测试自定义 API 端点

# 方案3：查看日志
# 检查 data/.openclaw/logs/ 中的错误日志
```

## 授权问题

### ❌ 问题：授权码无效

**诊断步骤：**
1. 检查授权码格式
2. 检查授权码是否已被使用
3. 检查网络连接

**解决方案：**
```powershell
# 方案1：检查格式
# 授权码格式：XXXX-XXXX-XXXX-XXXX

# 方案2：联系客服
# 提供购买凭证，申请重新绑定

# 方案3：检查网络
# 确保能够访问授权验证服务器
```

### ❌ 问题：硬件ID不匹配

**诊断步骤：**
1. 检查是否更换了设备
2. 检查是否修改了硬件
3. 检查授权绑定信息

**解决方案：**
```powershell
# 方案1：重新绑定
# 联系客服解绑旧设备，重新激活

# 方案2：检查硬件ID
# 获取当前硬件ID，对比授权信息

# 方案3：使用专业版
# 专业版支持多设备绑定
```

### ❌ 问题：授权已过期

**诊断步骤：**
1. 查看授权到期时间
2. 检查系统时间是否正确
3. 检查授权类型

**解决方案：**
```powershell
# 方案1：续费授权
# 访问官网续费授权

# 方案2：检查系统时间
# 确保系统时间准确

# 方案3：使用免费功能
# 授权过期后仍可使用基本功能
```

## 性能问题

### ❌ 问题：启动速度慢

**诊断步骤：**
1. 检查系统资源
2. 检查启动项
3. 检查磁盘性能

**解决方案：**
```powershell
# 方案1：清理临时文件
Remove-Item "$env:TEMP\*" -Recurse -Force

# 方案2：优化启动项
# 禁用不必要的启动程序

# 方案3：使用 SSD
# 将 OpenClaw 放在 SSD 上可提升启动速度
```

### ❌ 问题：运行时卡顿

**诊断步骤：**
1. 检查 CPU 和内存使用
2. 检查磁盘 I/O
3. 检查网络延迟

**解决方案：**
```powershell
# 方案1：关闭后台程序
Get-Process | Where-Object {$_.CPU -gt 100} | Stop-Process

# 方案2：增加内存
# 为系统分配更多内存

# 方案3：优化网络
# 使用更快的网络连接
```

### ❌ 问题：占用磁盘空间大

**诊断步骤：**
1. 检查各目录大小
2. 清理临时文件
3. 清理备份文件

**解决方案：**
```powershell
# 方案1：清理备份
Remove-Item "data\backup\*" -Recurse -Force

# 方案2：清理日志
Remove-Item "data\.openclaw\logs\*" -Recurse -Force

# 方案3：清理会话
# 删除不需要的会话记录
```

## 数据问题

### ❌ 问题：配置丢失

**诊断步骤：**
1. 检查配置文件是否存在
2. 检查文件权限
3. 检查是否有备份

**解决方案：**
```powershell
# 方案1：从备份恢复
# 从 data/backup 恢复配置文件

# 方案2：重新配置
# 手动重新配置所有设置

# 方案3：检查权限
# 确保有读写权限
```

### ❌ 问题：会话记录丢失

**诊断步骤：**
1. 检查会话文件
2. 检查磁盘空间
3. 检查文件是否被删除

**解决方案：**
```powershell
# 方案1：检查会话目录
Get-ChildItem "data\.openclaw\agents\main\sessions\"

# 方案2：恢复备份
# 从备份中恢复会话文件

# 方案3：检查日志
# 查看 data/.openclaw/logs/ 中的错误信息
```

### ❌ 问题：无法保存设置

**诊断步骤：**
1. 检查文件权限
2. 检查磁盘空间
3. 检查文件是否被锁定

**解决方案：**
```powershell
# 方案1：检查权限
icacls "data\.openclaw"

# 方案2：检查磁盘空间
Get-PSDrive -PSProvider FileSystem

# 方案3：关闭占用进程
# 确保没有其他进程占用文件
```

## 🔍 高级诊断

### 收集诊断信息

```powershell
# 收集系统信息
$systemInfo = @{
    OS = (Get-WmiObject Win32_OperatingSystem).Caption
    Version = (Get-WmiObject Win32_OperatingSystem).Version
    NodeVersion = if (Test-Path "app\runtime\node-win-x64\node.exe") { & "app\runtime\node-win-x64\node.exe" --version }
    OpenClawVersion = (Get-Content "version.json" | ConvertFrom-Json).version
    NetworkStatus = if (Test-Connection www.baidu.com -Count 1 -Quiet) { "Online" } else { "Offline" }
}

# 输出诊断信息
$systemInfo | ConvertTo-Json
```

### 查看详细日志

```powershell
# 查看最新日志
Get-Content "data\.openclaw\logs\*.log" -Tail 50

# 查看错误日志
Select-String -Path "data\.openclaw\logs\*.log" -Pattern "ERROR|Exception"
```

### 重置配置

```powershell
# ⚠️ 警告：这将删除所有配置
# 备份当前配置
Copy-Item "data\.openclaw" "data\.openclaw.backup" -Recurse

# 重置配置
Remove-Item "data\.openclaw\*" -Recurse -Force

# 重启 OpenClaw
# 将自动创建默认配置
```

## 📞 获取帮助

如果以上方法都无法解决问题：

1. **提交 Issue**: [GitHub Issues](https://github.com/jinge5998/openclaw-version/issues)
2. **查看文档**: [FAQ.md](FAQ.md)
3. **联系支持**: 发送邮件至项目维护者

提交 Issue 时请包含：
- 系统信息（OS、版本等）
- 错误信息或截图
- 已尝试的解决方法
- 相关日志文件

---

© 2026 OpenClaw Team
