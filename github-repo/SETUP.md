# 快速设置指南

## 第一步：创建 GitHub 仓库

1. 登录 GitHub
2. 点击右上角 `+` → `New repository`
3. 填写仓库信息：
   - Repository name: `openclaw-version`
   - Description: `OpenClaw 版本信息`
   - 选择 `Public`
   - 勾选 `Add a README file`
4. 点击 `Create repository`

## 第二步：上传文件

### 方法一：网页上传
1. 进入仓库页面
2. 点击 `Add file` → `Upload files`
3. 上传以下文件：
   - `README.md`
   - `version.json`
4. 点击 `Commit changes`

### 方法二：Git 命令
```bash
# 克隆仓库
git clone https://github.com/你的用户名/openclaw-version.git
cd openclaw-version

# 复制文件
cp /path/to/README.md .
cp /path/to/version.json .

# 提交
git add .
git commit -m "初始化版本信息"
git push origin main
```

## 第三步：配置启动器

编辑 `U-Claw-Launcher.ps1`，修改第 30-31 行：

```powershell
# 将 your-username 改为你的 GitHub 用户名
$script:NETWORK_VERSION_URL = "https://cdn.jsdelivr.net/gh/your-username/openclaw-version@main/version.json"
$script:NETWORK_VERSION_URL_BACKUP = "https://raw.githubusercontent.com/your-username/openclaw-version/main/version.json"
```

## 第四步：测试

1. 启动 OpenClaw 启动器
2. 点击 `升级 OpenClaw` 按钮
3. 检查是否能正确获取版本信息

## 发布更新

当需要发布新版本时：

1. 修改 `version.json` 中的版本号和更新日志
2. 更新 `downloadUrl` 为新的下载链接
3. 提交更改到 GitHub

```bash
git add version.json
git commit -m "发布 v5.1.0"
git push
```

客户端会在几分钟内收到更新通知！
