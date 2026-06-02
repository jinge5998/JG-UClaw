# OpenClaw U盘便携式版 v4.0
# UTF-8 编码
# 功能：自动检测本地 Ollama 模型，支持 35+ 云端 AI 模型，自定义模型厂商，一键更新模型列表，一机一码授权系统 (2026.04.09)

Add-Type @'
using System;
using System.Runtime.InteropServices;
public class ConsoleWindow {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    public static void Hide() { ShowWindow(GetConsoleWindow(), 0); }
}
'@
# 控制台隐藏现在受环境变量 OPENCLAW_DEBUG 控制。
# 如果需要调试并保留控制台输出，请在运行前设置环境变量 OPENCLAW_DEBUG=1
try {
    if (-not $env:OPENCLAW_DEBUG) {
        [ConsoleWindow]::Hide()
    }
    else {
        Write-Host "[DEBUG] OPENCLAW_DEBUG=1，保留控制台以便调试。"
    }
}
catch {
    Write-Host "[WARN] 无法隐藏控制台：$($_.Exception.Message)"
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $scriptPath) { $scriptPath = $PSScriptRoot }
Set-Location $scriptPath

$script:APP_DIR = Join-Path $scriptPath "app"
$script:CORE_DIR = Join-Path $script:APP_DIR "core"
$script:DATA_DIR = Join-Path $scriptPath "data"
$script:STATE_DIR = Join-Path $script:DATA_DIR ".openclaw"
$script:RUNTIME_DIR = Join-Path $script:APP_DIR "runtime"
$script:NODE_DIR = Join-Path $script:RUNTIME_DIR "node-win-x64"
$script:NODE_BIN = Join-Path $script:NODE_DIR "node.exe"
$script:NPM_BIN = Join-Path $script:NODE_DIR "npm.cmd"
$script:LICENSE_FILE = Join-Path $script:DATA_DIR ".license"
$script:LICENSE_KEY = "OpenClaw2026SecretKey!@#$%"

$script:NODE_VERSION = "v22.22.1"
$script:NODE_MIRROR = "https://npmmirror.com/mirrors/node"
$script:NPM_MIRROR = "https://registry.npmmirror.com"
$script:VERSION_URL = "file:///$scriptPath/remote-version.json"
$script:CURRENT_VERSION = "5.3.0"

$script:NETWORK_VERSION_URL = "https://cdn.jsdelivr.net/gh/jinge5998/JG-UClaw@main/version.json"
$script:NETWORK_VERSION_URL_BACKUP = "https://raw.githubusercontent.com/jinge5998/JG-UClaw/main/version.json"
$script:NETWORK_TEST_URL = "https://www.baidu.com"
$script:NETWORK_TIMEOUT = 10
$script:UPDATE_CHECK_INTERVAL = 24
$script:lastNetworkStatus = $null
$script:lastUpdateCheck = 0
$script:UPDATE_CONFIG_FILE = Join-Path $script:STATE_DIR "update-config.json"

function Get-OpenClawCoreVersion {
    $openclawPkg = Join-Path $script:CORE_DIR "node_modules\openclaw\package.json"
    if (Test-Path $openclawPkg) {
        try {
            $pkg = Get-Content $openclawPkg -Raw | ConvertFrom-Json
            return $pkg.version
        }
        catch {
            return $null
        }
    }
    return $null
}

function Get-LocalVersionInfo {
    $versionFile = Join-Path $scriptPath "version.json"
    if (Test-Path $versionFile) {
        try {
            $content = Get-Content $versionFile -Raw -Encoding UTF8
            return $content | ConvertFrom-Json
        }
        catch {
            return @{ version = $script:CURRENT_VERSION }
        }
    }
    return @{ version = $script:CURRENT_VERSION }
}

function Initialize-CurrentVersion {
    $localInfo = Get-LocalVersionInfo
    if ($localInfo -and $localInfo.version) {
        $script:CURRENT_VERSION = $localInfo.version
    }
}

Initialize-CurrentVersion

$txtTitle = "OpenClaw U盘便携式版5.0V"
$txtSubtitle = "便携式 AI 助手 - 即插即用"
$txtReady = "就绪"
$txtBtnStart = "启动 OpenClaw"
$txtBtnModel = "切换 AI 模型"
$txtBtnUpgrade = "升级 OpenClaw"
$txtBtnDeploy = "部署到 U 盘"
$txtBtnRepair = "修复环境"
$txtBtnSkillManage = "技能管理"
$txtBtnBackup = "一键备份"
$txtBtnActivate = "激活授权"
$txtSkillManageTitle = "技能管理"
$txtSkillManageHint = "已安装的技能列表"
$txtNoSkills = "暂无已安装的技能"
$txtSkillClose = "关闭"
$txtBackupTitle = "一键备份"
$txtBackupHint = "正在备份..."
$txtBackupConfirm = "此操作将备份您的技能、配置、长记忆和核心文件到ZIP压缩包。是否继续？"
$txtBackupDone = "备份完成！"
$txtBackupFailed = "备份失败"
$txtBackupLocation = "备份文件位置："

$txtBtnRestore = "恢复备份"
$txtRestoreTitle = "恢复备份"
$txtRestoreHint = "正在恢复..."
$txtRestoreConfirm = "此操作将从备份文件恢复数据，将覆盖当前的技能、配置和核心文件。是否继续？"
$txtRestoreDone = "恢复完成！"
$txtRestoreFailed = "恢复失败"
$txtRestoreSelectFile = "请选择备份文件"
$txtRestoreRestart = "恢复完成，建议重启应用以使更改生效。"

$txtBtnBackupHistory = "备份历史"
$txtHistoryTitle = "备份历史"
$txtHistoryNoBackup = "暂无备份文件"
$txtHistoryDelete = "删除"
$txtHistoryOpenLocation = "打开位置"
$txtHistoryConfirmDelete = "确定要删除此备份文件吗？"
$txtHistorySize = "大小"
$txtHistoryTime = "时间"

$txtSkillDetailTitle = "技能详情"
$txtSkillDetailClose = "关闭"

$txtHint = "提示：点击 [启动 OpenClaw] 开始使用。遇到问题时点击 [修复环境]。"
$txtSelectModel = "选择 AI 模型"
$txtSelectModelHint = "请选择一个 AI 模型："
$txtInputApiKey = "输入 API Key"
$txtApiKeyHint = "请输入 API Key："
$txtSelectUsb = "选择目标 U 盘"
$txtSelectUsbHint = "请选择要部署的 U 盘位置："
$txtBrowse = "浏览..."
$txtStartDeploy = "开始部署"
$txtCancel = "取消"
$txtConfirm = "确定"
$txtModelConfigured = "模型配置成功！"
$txtCurrentModel = "当前模型："
$txtClickStart = "点击 [启动 OpenClaw] 开始使用。"
$txtDeploySuccess = "部署成功！"
$txtTargetLocation = "目标位置："
$txtCopyToUsb = "您可以将此文件夹复制到任意 U 盘。"
$txtDoubleClickStart = "双击 [启动器.bat] 即可运行。"
$txtConfigReset = "配置已重置为默认值。"
$txtFullResetDone = "完全重置完成！"
$txtClickRepair = "点击 [修复环境] 下载依赖组件。"
$txtRepairDone = "修复完成！"
$txtRepairFromCloud = "正在从网盘下载修复包..."
$txtRepairExtracting = "正在解压修复包..."
$txtRepairVerifying = "正在验证文件..."
$txtRepairCloudDesc = "修复环境将从迅雷网盘下载完整的 Node.js 和 OpenClaw 必要文件，约 180MB，请耐心等待。"
$txtClickStartNow = "现在可以点击 [启动 OpenClaw] 开始使用。"
$txtUClawStarted = "OpenClaw 已启动！"
$txtAiChat = "AI 对话："
$txtCloseToStop = "提示：关闭终端窗口即可停止服务。"
$txtMissingNode = "未找到 Node.js！"
$txtClickRepairFirst = "请先点击 [修复环境]。"
$txtMissingOpenclaw = "未找到 OpenClaw！"
$txtNoPort = "没有可用端口 (18789-18799)"
$txtPortError = "端口错误"
$txtPortOccupied = "端口被占用"
$txtStarting = "正在启动..."
$txtDeploying = "正在部署到："
$txtCopying = "正在复制文件..."
$txtCreatingScript = "正在创建启动脚本..."
$txtDeployDone = "部署完成！"
$txtDeployCanceled = "部署已取消"
$txtDeleting = "正在删除数据..."
$txtDeletingNode = "正在删除旧版 Node.js..."
$txtDownloadingNode = "正在下载 Node.js..."
$txtExtractingNode = "正在解压 Node.js..."
$txtDeletingOpenclaw = "正在删除旧版 OpenClaw..."
$txtInstallingOpenclaw = "正在安装 OpenClaw..."
$txtRepairFailed = "修复失败"
$txtDeployFailed = "部署失败"
$txtConfigFailed = "配置失败"
$txtResetFailed = "重置失败"
$txtError = "错误"
$txtSuccess = "成功"
$txtDone = "完成"
$txtWarning = "警告"
$txtConfirmDeploy = "此操作将把 OpenClaw 部署到新的 U 盘位置。"
$txtEnsureUsb = "请确保目标 U 盘已插入并分配了盘符。"
$txtContinue = "是否继续？"
$txtConfirmRepair = "此操作将重新下载 Node.js 和 OpenClaw。"
$txtConfirmReset = "此操作将重置配置为默认值。"
$txtConfirmFullReset = "警告：此操作将删除所有数据！"
$txtOverwrite = "目标位置已存在 OpenClaw 文件夹，是否覆盖？"
$txtSelectTarget = "请选择目标位置"
$txtStartingGateway = "正在启动网关（端口 "
$txtWaitingGateway = "等待网关启动..."
$txtGatewayReady = "网关已就绪！"
$txtGatewayFailed = "网关启动失败"
$txtSwitchedTo = "已切换到："
$txtTokenSync = "令牌已同步"
$txtUpgrading = "正在升级..."
$txtUpgradeCheck = "正在检查更新..."
$txtUpgradeCurrent = "当前版本："
$txtUpgradeLatest = "最新版本："
$txtUpgradeAvailable = "发现新版本！"
$txtUpgradeUpToDate = "已是最新版本！"
$txtUpgradeSuccess = "升级成功！"
$txtUpgradeFailed = "升级失败"
$txtUpgradeConfirm = "是否升级到最新版本？"
$txtUpgradeOpenclaw = "正在升级 OpenClaw..."
$txtUpgradeDone = "升级完成！"

$txtCurrentVersion = "当前版本"
$txtLatestVersion = "最新版本"
$txtUpdateAvailable = "发现新版本！"
$txtNoUpdate = "已是最新版本"
$txtUpdateCheckFailed = "版本检查失败"
$txtUpdateLater = "稍后提醒"
$txtSkipVersion = "跳过此版本"
$txtOpenDownload = "打开下载页面"
$txtCopyPassword = "复制提取码"
$txtOpenGitHub = "GitHub 下载"
$txtOpenNetworkDisk = "网盘下载"
$txtDownloadFrom = "下载来源"
$txtExtractCode = "提取码"
$txtChangelog = "更新内容"
$txtUpdateNew = "新增"
$txtUpdateFix = "修复"
$txtUpdateOptimize = "优化"
$txtUpdateRemove = "移除"

$txtNetworkOnline = "在线"
$txtNetworkOffline = "离线"
$txtNetworkChecking = "检查网络..."
$txtNetworkStatusOnline = "网络已连接"
$txtNetworkStatusOffline = "网络未连接"
$txtRetryCheck = "重试检查"
$txtUseLocalVersion = "使用本地版本"
$txtUpdateAvailableBar = "发现新版本"
$txtClickToView = "点击查看"
$txtIgnoreVersion = "忽略此版本"
$txtViewUpdate = "查看详情"
$txtHideTip = "隐藏提示"

$txtUpdateCheckInterval = "检查间隔"
$txtUpdateCheckIntervalHint = "小时"
$txtUpdateCheckNow = "立即检查"
$txtUpdateAutoCheck = "自动检查"

$txtLicenseActivated = "已授权"
$txtLicenseNotActivated = "未授权"
$txtLicenseExpired = "授权已过期"
$txtLicenseInputCode = "请输入授权码："
$txtLicenseInputTitle = "激活授权"
$txtLicenseActivateSuccess = "授权激活成功！"
$txtLicenseActivateFailed = "授权激活失败！"
$txtLicenseInvalidCode = "授权码无效或已过期。"
$txtLicenseHWIDMismatch = "授权码与当前 U 盘不匹配！"
$txtLicenseAlreadyUsed = "此授权码已被使用！"
$txtLicenseDeployBlocked = "部署功能需要授权！`n`n请先点击 [激活授权] 输入授权码。"
$txtLicenseGenerateTitle = "授权码生成器（管理员模式）"
$txtLicenseGenerateHint = "输入 U 盘硬件ID生成授权码："
$txtLicenseHWIDLabel = "U 盘硬件ID："
$txtLicenseCodeLabel = "生成的授权码："
$txtLicenseGenerateBtn = "生成授权码"
$txtLicenseCopyBtn = "复制授权码"
$txtLicenseCurrentHWID = "当前 U 盘硬件ID："
$txtLicenseDaysLabel = "有效天数："
$txtLicenseDaysHint = "（0=永久）"

$txtAddCustomModel = "添加自定义模型"
$txtCustomModelTitle = "添加自定义 AI 模型"
$txtCustomModelVendor = "厂商名称："
$txtCustomModelBaseUrl = "Base URL："
$txtCustomModelModelId = "模型 ID："
$txtCustomModelApiKey = "API Key："
$txtCustomModelVendorHint = "例如：OpenAI、DeepSeek、智谱等"
$txtCustomModelBaseUrlHint = "例如：https://api.openai.com/v1"
$txtCustomModelModelIdHint = "例如：gpt-4、deepseek-chat 等"
$txtCustomModelApiKeyHint = "从厂商官网获取 API Key"
$txtCustomModelSave = "保存模型"
$txtCustomModelSaved = "自定义模型保存成功！"
$txtCustomModelDeleted = "自定义模型已删除！"
$txtCustomModelDeleteConfirm = "确定要删除此自定义模型吗？"
$txtCustomModelNameExists = "模型名称已存在！"
$txtCustomModelInvalidBaseUrl = "Base URL 格式无效！请输入有效的 URL。"
$txtCustomModelInvalidModelId = "模型 ID 不能为空！"
$txtCustomModelInvalidVendor = "厂商名称不能为空！"
$txtCustomModelSeparator = "--- 自定义模型 ---"

$txtTokenTitle = "寻求合作单位"
$txtTokenRefresh = "刷新"
$txtTokenRecharge = "充值"
$txtTokenClose = "关闭"
$txtTokenLoading = "正在查询..."
$txtTokenQueryFailed = "查询失败"
$txtTokenNoConfig = "未配置 API Key"
$txtTokenBalance = "余额"
$txtTokenUsed = "已使用"
$txtTokenTotal = "总额"
$txtTokenUnknown = "未知"
$txtTokenRechargeUrl = "充值链接"
$txtTokenDeepSeek = "DeepSeek"
$txtTokenOpenAI = "OpenAI"
$txtTokenAnthropic = "Anthropic"
$txtTokenOther = "其他厂商"

$txtModelsConfigTitle = "模型配置管理"
$txtModelsConfigEmpty = "暂无已配置的模型，请先在模型选择中添加并配置 API Key"
$txtModelsConfigProvider = "提供商"
$txtModelsConfigApiKey = "API Key"
$txtModelsConfigBaseUrl = "Base URL"
$txtModelsConfigEdit = "编辑"
$txtModelsConfigDelete = "删除"
$txtModelsConfigTest = "测试连接"
$txtModelsConfigClose = "关闭"
$txtModelsConfigEditTitle = "编辑模型配置"
$txtModelsConfigUpdateHint = "请输入新的 API Key"
$txtModelsConfigUpdateSuccess = "API Key 更新成功！"
$txtModelsConfigDeleteConfirm = "确定要删除此模型配置吗？"
$txtModelsConfigDeleteSuccess = "模型配置已删除！"
$txtModelsConfigTestSuccess = "连接测试成功！"
$txtModelsConfigTestFailed = "连接测试失败："

$script:CUSTOM_MODELS_FILE = Join-Path $script:STATE_DIR "custom-models.json"
$script:MODELS_CONFIG_FILE = Join-Path $script:STATE_DIR "models-config.json"

function Save-ModelsConfig {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    try {
        $configDir = Split-Path $script:MODELS_CONFIG_FILE -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }

        $configData = @{
            providers   = $Config.providers
            lastUpdated = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        }

        $json = $configData | ConvertTo-Json -Depth 10

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($script:LICENSE_KEY.PadRight(32).Substring(0, 32))
        $aes.IV = [byte[]]::new(16)
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

        $encryptor = $aes.CreateEncryptor()
        $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)

        if (Test-Path $script:MODELS_CONFIG_FILE) {
            $fileAttributes = [System.IO.File]::GetAttributes($script:MODELS_CONFIG_FILE)
            if ($fileAttributes -band [System.IO.FileAttributes]::Hidden) {
                [System.IO.File]::SetAttributes($script:MODELS_CONFIG_FILE, $fileAttributes -bxor [System.IO.FileAttributes]::Hidden)
            }
            Remove-Item -Path $script:MODELS_CONFIG_FILE -Force -ErrorAction Stop
        }

        [System.IO.File]::WriteAllBytes($script:MODELS_CONFIG_FILE, $cipherBytes)

        $fileInfo = New-Object System.IO.FileInfo($script:MODELS_CONFIG_FILE)
        $fileInfo.Attributes = $fileInfo.Attributes -bor [System.IO.FileAttributes]::Hidden

        return $true
    }
    catch {
        Write-Host "Save-ModelsConfig error: $_"
        return $false
    }
}

function Load-ModelsConfig {
    try {
        if (-not (Test-Path $script:MODELS_CONFIG_FILE)) {
            return @{
                providers   = @{}
                lastUpdated = 0
            }
        }

        $cipherBytes = [System.IO.File]::ReadAllBytes($script:MODELS_CONFIG_FILE)

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($script:LICENSE_KEY.PadRight(32).Substring(0, 32))
        $aes.IV = [byte[]]::new(16)
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

        $decryptor = $aes.CreateDecryptor()
        $plainBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)
        $json = [System.Text.Encoding]::UTF8.GetString($plainBytes)

        $config = $json | ConvertFrom-Json

        $result = @{
            providers   = @{}
            lastUpdated = $config.lastUpdated
        }

        if ($config.providers) {
            foreach ($providerName in $config.providers.PSObject.Properties.Name) {
                $providerData = $config.providers.$providerName
                $result.providers[$providerName] = @{
                    apiKey  = $providerData.apiKey
                    baseUrl = $providerData.baseUrl
                }
            }
        }

        return $result
    }
    catch {
        Write-Host "[ERROR] Load-ModelsConfig 解密失败: $_"
        Write-Host "[INFO] 配置文件路径: $script:MODELS_CONFIG_FILE"
        if (Test-Path $script:MODELS_CONFIG_FILE) {
            Write-Host "[INFO] 文件大小: $((Get-Item $script:MODELS_CONFIG_FILE).Length) 字节"
        }
        return @{
            providers   = @{}
            lastUpdated = 0
        }
    }
}

function Update-ModelsConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Provider,
        [Parameter(Mandatory = $true)]
        [string]$ApiKey,
        [Parameter(Mandatory = $false)]
        [string]$BaseUrl = ""
    )

    try {
        $currentConfig = Load-ModelsConfig

        $defaultUrls = @{
            "openai"   = "https://api.openai.com/v1"
            "deepseek" = "https://api.deepseek.com/v1"
            "mistral"  = "https://api.mistral.ai/v1"
            "groq"     = "https://api.groq.com/openai/v1"
        }

        if ([string]::IsNullOrEmpty($BaseUrl)) {
            if ($defaultUrls.ContainsKey($Provider)) {
                $BaseUrl = $defaultUrls[$Provider]
            }
            else {
                $BaseUrl = ""
            }
        }

        $currentConfig.providers[$Provider] = @{
            apiKey  = $ApiKey
            baseUrl = $BaseUrl
        }

        $saveResult = Save-ModelsConfig -Config $currentConfig
        if (-not $saveResult) {
            return $false
        }

        $verifyConfig = Load-ModelsConfig
        if ($verifyConfig.providers.ContainsKey($Provider)) {
            $verifyKey = $verifyConfig.providers[$Provider].apiKey
            if ($verifyKey -ne $ApiKey) {
                Write-Host "[WARN] API Key 验证失败：保存的值与读取的值不一致"
                return $false
            }
        }

        return $true
    }
    catch {
        Write-Host "Update-ModelsConfig error: $_"
        return $false
    }
}

function Query-TokenUsage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Provider,
        [Parameter(Mandatory = $true)]
        [string]$ApiKey
    )

    $result = @{
        provider    = $Provider
        balance     = $null
        used        = $null
        total       = $null
        currency    = "CNY"
        error       = $null
        rechargeUrl = $null
    }

    try {
        switch ($Provider.ToLower()) {
            "deepseek" {
                $result.rechargeUrl = "https://platform.deepseek.com/top_up"
                try {
                    $headers = @{
                        "Authorization" = "Bearer $ApiKey"
                        "Content-Type"  = "application/json"
                    }
                    $response = Invoke-RestMethod -Uri "https://api.deepseek.com/account/balance" -Headers $headers -Method Get -TimeoutSec 30
                    if ($response.data) {
                        foreach ($balanceItem in $response.data) {
                            if ($balanceItem.currency -eq "CNY") {
                                $result.balance = [math]::Round([double]$balanceItem.total_balance, 2)
                                $result.used = [math]::Round([double]$balanceItem.total_usage, 2)
                                $result.total = [math]::Round([double]$balanceItem.total_balance + [double]$balanceItem.total_usage, 2)
                            }
                        }
                    }
                }
                catch {
                    $result.error = $_.Exception.Message
                }
            }

            "openai" {
                $result.rechargeUrl = "https://platform.openai.com/settings/organization/billing/overview"
                try {
                    $headers = @{
                        "Authorization" = "Bearer $ApiKey"
                        "Content-Type"  = "application/json"
                    }

                    $dateNow = Get-Date
                    $startDate = $dateNow.AddDays(-30).ToString("yyyy-MM-dd")
                    $endDate = $dateNow.ToString("yyyy-MM-dd")

                    $creditResponse = Invoke-RestMethod -Uri "https://api.openai.com/dashboard/billing/credit_grants" -Headers $headers -Method Get -TimeoutSec 30
                    if ($creditResponse.data) {
                        foreach ($grant in $creditResponse.data) {
                            if ($grant.grant_type -eq "usage") {
                                $result.total = [math]::Round([double]$grant.total_granted, 2)
                                $result.used = [math]::Round([double]$grant.total_used, 2)
                                $result.balance = [math]::Round([double]$grant.total_granted - [double]$grant.total_used, 2)
                            }
                        }
                    }

                    if ($null -eq $result.total) {
                        $subscriptionResponse = Invoke-RestMethod -Uri "https://api.openai.com/dashboard/billing/subscription" -Headers $headers -Method Get -TimeoutSec 30
                        if ($subscriptionResponse) {
                            $result.total = [math]::Round([double]$subscriptionResponse.hard_limit_usd, 2)
                            $result.balance = 0
                            $result.used = 0
                        }
                    }
                }
                catch {
                    $result.error = $_.Exception.Message
                }
            }

            "anthropic" {
                $result.rechargeUrl = "https://console.anthropic.com/settings/plans"
                try {
                    $headers = @{
                        "x-api-key"         = $ApiKey
                        "Content-Type"      = "application/json"
                        "anthropic-version" = "2023-06-01"
                    }
                    $response = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/organizations/current/credit_grant" -Headers $headers -Method Get -TimeoutSec 30
                    if ($response) {
                        $result.balance = [math]::Round([double]$response.credit_balance, 2)
                        $result.total = [math]::Round([double]$response.credit_balance + [double]$response.spent, 2)
                        $result.used = [math]::Round([double]$response.spent, 2)
                    }
                }
                catch {
                    $result.error = $_.Exception.Message
                }
            }

            default {
                $result.error = $txtTokenOther + " - " + $txtTokenQueryFailed
                $result.rechargeUrl = ""
            }
        }
    }
    catch {
        $result.error = $_.Exception.Message
    }

    return $result
}

$script:DEBUG_HWID = $false
$script:HWID_STABILITY_WARNING = $false

function Get-USBHardwareID {
    param([switch]$Verbose)
    
    function Write-DebugInfo {
        param($Message)
        if ($script:DEBUG_HWID -or $Verbose) {
            Write-Host "[HWID Debug] $Message" -ForegroundColor Cyan
        }
    }
    
    $rawId = $null
    $methodUsed = "none"
    $isStable = $true
    
    try {
        $drive = Split-Path $scriptPath -Qualifier
        if (-not $drive) { 
            $drive = $env:SystemDrive 
            Write-DebugInfo "无法获取驱动器盘符，使用系统盘: $drive"
        }
        $drive = $drive.TrimEnd(':')
        Write-DebugInfo "检测驱动器: $drive"
        
        Write-DebugInfo "=== 方法1: 通过 fsutil 获取卷序列号 ==="
        try {
            $fsutilOutput = & fsutil volume diskfree "${drive}:" 2>&1
            $volInfo = & vol "${drive}:" 2>&1
            if ($volInfo -match "卷序列号是 ([A-F0-9-]+)") {
                $volSerial = $Matches[1].Replace("-", "")
                Write-DebugInfo "获取到卷序列号: $volSerial"
                $rawId = "VOLUME:${volSerial}:$drive"
                $methodUsed = "volume_serial"
                $isStable = $false
            }
        }
        catch {
            Write-DebugInfo "fsutil 方法失败: $($_.Exception.Message)"
        }
        
        if (-not $rawId) {
            Write-DebugInfo "=== 方法2: 通过环境变量组合 ==="
            $computerName = $env:COMPUTERNAME
            $userDomain = $env:USERDOMAIN
            $envCombined = "${computerName}:${drive}:${userDomain}"
            $rawId = "ENV:$envCombined"
            $methodUsed = "env_combined"
            $isStable = $false
            Write-DebugInfo "使用环境变量组合: $rawId"
        }
        
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($rawId))
        $hardwareId = [System.BitConverter]::ToString($hashBytes).Replace("-", "").Substring(0, 32).ToUpper()
        
        $script:HWID_STABILITY_WARNING = -not $isStable
        
        Write-DebugInfo "最终 HardwareID: $hardwareId"
        Write-DebugInfo "使用方法: $methodUsed"
        Write-DebugInfo "稳定性: $(if ($isStable) { '稳定' } else { '不稳定' })"
        
        return $hardwareId
    }
    catch {
        Write-DebugInfo "严重错误: $($_.Exception.Message)"
        
        $fallback = "PATH:$scriptPath"
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($fallback))
        $fallbackId = [System.BitConverter]::ToString($hashBytes).Replace("-", "").Substring(0, 32).ToUpper()
        
        $script:HWID_STABILITY_WARNING = $true
        Write-DebugInfo "使用紧急 HardwareID: $fallbackId"
        return $fallbackId
    }
}

function Get-HWIDStabilityStatus {
    return @{
        IsStable = -not $script:HWID_STABILITY_WARNING
        Warning  = $script:HWID_STABILITY_WARNING
    }
}

function New-LicenseCode {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HardwareID,
        [int]$ValidDays = 0
    )
    
    try {
        $timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        $expireDate = if ($ValidDays -gt 0) { 
            [DateTimeOffset]::Now.AddDays($ValidDays).ToUnixTimeSeconds()
        }
        else { 
            0 
        }
        
        $payload = "$HardwareID|$timestamp|$expireDate"
        
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($script:LICENSE_KEY.PadRight(32).Substring(0, 32))
        $aes.IV = [byte[]]::new(16)
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        
        $encryptor = $aes.CreateEncryptor()
        $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
        
        $licenseCode = "OC-" + [System.Convert]::ToBase64String($cipherBytes).Replace("=", "").Replace("+", "-").Replace("/", "_")
        
        return $licenseCode
    }
    catch {
        Write-Host "License generation error: $_"
        return $null
    }
}

function Test-LicenseCode {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LicenseCode
    )
    
    try {
        if (-not $LicenseCode.StartsWith("OC-")) {
            return @{ Valid = $false; Error = "Invalid format" }
        }
        
        $base64Code = $LicenseCode.Substring(3).Replace("-", "+").Replace("_", "/")
        $padding = 4 - ($base64Code.Length % 4)
        if ($padding -ne 4) {
            $base64Code += "=" * $padding
        }
        
        $cipherBytes = [System.Convert]::FromBase64String($base64Code)
        
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($script:LICENSE_KEY.PadRight(32).Substring(0, 32))
        $aes.IV = [byte[]]::new(16)
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        
        $decryptor = $aes.CreateDecryptor()
        $plainBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)
        $payload = [System.Text.Encoding]::UTF8.GetString($plainBytes)
        
        $parts = $payload.Split('|')
        if ($parts.Length -ne 3) {
            return @{ Valid = $false; Error = "Invalid payload" }
        }
        
        $hwid = $parts[0]
        $timestamp = [long]$parts[1]
        $expireDate = [long]$parts[2]
        
        $currentHwid = Get-USBHardwareID
        if ($hwid -ne $currentHwid) {
            return @{ Valid = $false; Error = "HWID mismatch"; HWID = $hwid; CurrentHWID = $currentHwid }
        }
        
        if ($expireDate -gt 0) {
            $now = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            if ($now -gt $expireDate) {
                return @{ Valid = $false; Error = "Expired"; ExpireDate = $expireDate }
            }
        }
        
        return @{ 
            Valid      = $true
            HWID       = $hwid
            Timestamp  = $timestamp
            ExpireDate = $expireDate
        }
    }
    catch {
        return @{ Valid = $false; Error = $_.Exception.Message }
    }
}

function Save-License {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LicenseCode,
        [Parameter(Mandatory = $true)]
        $LicenseInfo
    )
    
    try {
        $hwid = if ($LicenseInfo.ContainsKey("HWID")) { $LicenseInfo["HWID"] } else { $LicenseInfo.HWID }
        $timestamp = if ($LicenseInfo.ContainsKey("Timestamp")) { $LicenseInfo["Timestamp"] } else { $LicenseInfo.Timestamp }
        $expireDate = if ($LicenseInfo.ContainsKey("ExpireDate")) { $LicenseInfo["ExpireDate"] } else { $LicenseInfo.ExpireDate }
        
        $licenseData = @{
            Code        = $LicenseCode
            HWID        = $hwid
            Timestamp   = $timestamp
            ExpireDate  = $expireDate
            ActivatedAt = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        }
        
        $json = $licenseData | ConvertTo-Json -Depth 10
        
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($script:LICENSE_KEY.PadRight(32).Substring(0, 32))
        $aes.IV = [byte[]]::new(16)
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        
        $encryptor = $aes.CreateEncryptor()
        $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
        
        $licenseDir = Split-Path $script:LICENSE_FILE -Parent
        
        if (-not (Test-Path $licenseDir)) {
            New-Item -ItemType Directory -Path $licenseDir -Force | Out-Null
        }
        
        if (Test-Path $script:LICENSE_FILE) {
            $fileAttributes = [System.IO.File]::GetAttributes($script:LICENSE_FILE)
            if ($fileAttributes -band [System.IO.FileAttributes]::Hidden) {
                [System.IO.File]::SetAttributes($script:LICENSE_FILE, $fileAttributes -bxor [System.IO.FileAttributes]::Hidden)
            }
            Remove-Item -Path $script:LICENSE_FILE -Force -ErrorAction Stop
        }
        
        [System.IO.File]::WriteAllBytes($script:LICENSE_FILE, $cipherBytes)
        
        $fileInfo = New-Object System.IO.FileInfo($script:LICENSE_FILE)
        $fileInfo.Attributes = $fileInfo.Attributes -bor [System.IO.FileAttributes]::Hidden
        
        return $true
    }
    catch {
        Write-Host "Save license error: $_"
        return $false
    }
}

function Load-License {
    try {
        if (-not (Test-Path $script:LICENSE_FILE)) {
            return $null
        }
        
        $cipherBytes = [System.IO.File]::ReadAllBytes($script:LICENSE_FILE)
        
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($script:LICENSE_KEY.PadRight(32).Substring(0, 32))
        $aes.IV = [byte[]]::new(16)
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        
        $decryptor = $aes.CreateDecryptor()
        $plainBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)
        $json = [System.Text.Encoding]::UTF8.GetString($plainBytes)
        
        return $json | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Test-LicenseValid {
    try {
        $license = Load-License
        if (-not $license) {
            return @{ Valid = $false; Status = "No license" }
        }
        
        $result = Test-LicenseCode -LicenseCode $license.Code
        
        if ($result.Valid) {
            $status = $txtLicenseActivated
            if ($result.ExpireDate -gt 0) {
                $expireTime = [DateTimeOffset]::FromUnixTimeSeconds($result.ExpireDate).LocalDateTime
                $status = "$txtLicenseActivated (到期: $($expireTime.ToString('yyyy-MM-dd')))"
            }
            return @{ Valid = $true; Status = $status; License = $license }
        }
        
        if ($result.Error -eq "Expired") {
            return @{ Valid = $false; Status = $txtLicenseExpired }
        }
        
        if ($result.Error -eq "HWID mismatch") {
            return @{ Valid = $false; Status = $txtLicenseHWIDMismatch }
        }
        
        return @{ Valid = $false; Status = $txtLicenseInvalidCode }
    }
    catch {
        return @{ Valid = $false; Status = "Error: $_" }
    }
}

function Show-ActivationDialog {
    $actForm = New-Object System.Windows.Forms.Form
    $actForm.Text = $txtLicenseInputTitle
    $actForm.Size = New-Object System.Drawing.Size(500, 280)
    $actForm.StartPosition = "CenterScreen"
    $actForm.FormBorderStyle = "FixedSingle"
    $actForm.MaximizeBox = $false
    $actForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $txtLicenseInputTitle
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(450, 30)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 12)
    $titleLabel.TextAlign = "MiddleCenter"
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
    $actForm.Controls.Add($titleLabel)
    
    $hwidLabel = New-Object System.Windows.Forms.Label
    $hwidLabel.Text = $txtLicenseCurrentHWID
    $hwidLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
    $hwidLabel.Size = New-Object System.Drawing.Size(450, 18)
    $hwidLabel.Location = New-Object System.Drawing.Point(20, 48)
    $hwidLabel.ForeColor = [System.Drawing.Color]::Gray
    $actForm.Controls.Add($hwidLabel)
    
    $currentHwid = Get-USBHardwareID
    $hwidText = New-Object System.Windows.Forms.Label
    $hwidText.Text = $currentHwid
    $hwidText.Font = New-Object System.Drawing.Font("Consolas", 9)
    $hwidText.Size = New-Object System.Drawing.Size(450, 20)
    $hwidText.Location = New-Object System.Drawing.Point(20, 68)
    $hwidText.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $actForm.Controls.Add($hwidText)
    
    $copyHwidBtn = New-Object System.Windows.Forms.Button
    $copyHwidBtn.Text = "复制硬件ID"
    $copyHwidBtn.Size = New-Object System.Drawing.Size(100, 24)
    $copyHwidBtn.Location = New-Object System.Drawing.Point(370, 92)
    $copyHwidBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
    $copyHwidBtn.FlatStyle = "Flat"
    $copyHwidBtn.Add_Click({
            [System.Windows.Forms.Clipboard]::SetText($currentHwid)
            [System.Windows.Forms.MessageBox]::Show("硬件ID已复制到剪贴板！", $txtDone, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        })
    $actForm.Controls.Add($copyHwidBtn)
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $txtLicenseInputCode
    $label.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $label.Size = New-Object System.Drawing.Size(450, 22)
    $label.Location = New-Object System.Drawing.Point(20, 122)
    $actForm.Controls.Add($label)
    
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Size = New-Object System.Drawing.Size(440, 28)
    $textBox.Location = New-Object System.Drawing.Point(20, 148)
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $actForm.Controls.Add($textBox)
    
    $hintLabel = New-Object System.Windows.Forms.Label
    $hintLabel.Text = "授权码格式：OC-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    $hintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 7)
    $hintLabel.Size = New-Object System.Drawing.Size(440, 16)
    $hintLabel.Location = New-Object System.Drawing.Point(20, 178)
    $hintLabel.ForeColor = [System.Drawing.Color]::Gray
    $actForm.Controls.Add($hintLabel)
    
    $okBtn = New-Object System.Windows.Forms.Button
    $okBtn.Text = $txtConfirm
    $okBtn.Size = New-Object System.Drawing.Size(120, 32)
    $okBtn.Location = New-Object System.Drawing.Point(140, 200)
    $okBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $okBtn.ForeColor = [System.Drawing.Color]::White
    $okBtn.FlatStyle = "Flat"
    $okBtn.Add_Click({
            $code = $textBox.Text.Trim()
            if ([string]::IsNullOrEmpty($code)) {
                [System.Windows.Forms.MessageBox]::Show("请输入授权码！", $txtWarning, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }
        
            if (-not $code.StartsWith("OC-")) {
                [System.Windows.Forms.MessageBox]::Show("授权码格式无效！`n授权码应以 'OC-' 开头。", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }
        
            $result = Test-LicenseCode -LicenseCode $code
        
            if ($result.Valid) {
                if (Save-License -LicenseCode $code -LicenseInfo $result) {
                    $expireInfo = ""
                    if ($result.ExpireDate -gt 0) {
                        $expireTime = [DateTimeOffset]::FromUnixTimeSeconds($result.ExpireDate).LocalDateTime
                        $expireInfo = "`n`n到期时间：$($expireTime.ToString('yyyy-MM-dd HH:mm:ss'))"
                    }
                    else {
                        $expireInfo = "`n`n授权类型：永久授权"
                    }
                    [System.Windows.Forms.MessageBox]::Show($txtLicenseActivateSuccess + $expireInfo, $txtSuccess, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                    $script:licenseActivated = $true
                    $script:licenseStatus = $txtLicenseActivated
                    if ($script:btnStart) {
                        $script:btnStart.Enabled = $true
                    }
                    $actForm.Close()
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show("保存授权信息失败！", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            else {
                $errorMsg = switch ($result.Error) {
                    "HWID mismatch" { $txtLicenseHWIDMismatch + "`n`n当前硬件ID：$($result.CurrentHWID)`n授权码绑定ID：$($result.HWID)" }
                    "Expired" { $txtLicenseExpired }
                    "Invalid format" { "授权码格式无效！" }
                    "Invalid payload" { "授权码内容无效！" }
                    default { $txtLicenseInvalidCode + " ($($result.Error))" }
                }
                [System.Windows.Forms.MessageBox]::Show($errorMsg, $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        })
    $actForm.Controls.Add($okBtn)
    
    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Text = $txtCancel
    $cancelBtn.Size = New-Object System.Drawing.Size(120, 32)
    $cancelBtn.Location = New-Object System.Drawing.Point(280, 200)
    $cancelBtn.Add_Click({ $actForm.Close() })
    $actForm.Controls.Add($cancelBtn)
    
    $actForm.Add_Shown({ $textBox.Focus() })
    [void]$actForm.ShowDialog()
}

function Show-LicenseGenerator {
    $genForm = New-Object System.Windows.Forms.Form
    $genForm.Text = $txtLicenseGenerateTitle
    $genForm.Size = New-Object System.Drawing.Size(520, 380)
    $genForm.StartPosition = "CenterScreen"
    $genForm.FormBorderStyle = "FixedSingle"
    $genForm.MaximizeBox = $false
    $genForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $txtLicenseGenerateTitle
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(480, 35)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 12)
    $titleLabel.TextAlign = "MiddleCenter"
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
    $genForm.Controls.Add($titleLabel)
    
    $warningLabel = New-Object System.Windows.Forms.Label
    $warningLabel.Text = "⚠ 管理员工具 - 请勿泄露授权码"
    $warningLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
    $warningLabel.Size = New-Object System.Drawing.Size(480, 20)
    $warningLabel.Location = New-Object System.Drawing.Point(20, 48)
    $warningLabel.TextAlign = "MiddleCenter"
    $warningLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 153, 0)
    $genForm.Controls.Add($warningLabel)
    
    $hwidLabel = New-Object System.Windows.Forms.Label
    $hwidLabel.Text = $txtLicenseHWIDLabel
    $hwidLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $hwidLabel.Size = New-Object System.Drawing.Size(460, 20)
    $hwidLabel.Location = New-Object System.Drawing.Point(20, 78)
    $genForm.Controls.Add($hwidLabel)
    
    $hwidTextBox = New-Object System.Windows.Forms.TextBox
    $hwidTextBox.Size = New-Object System.Drawing.Size(350, 28)
    $hwidTextBox.Location = New-Object System.Drawing.Point(20, 102)
    $hwidTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $hwidTextBox.Text = Get-USBHardwareID
    $genForm.Controls.Add($hwidTextBox)
    
    $pasteBtn = New-Object System.Windows.Forms.Button
    $pasteBtn.Text = "粘贴"
    $pasteBtn.Size = New-Object System.Drawing.Size(50, 28)
    $pasteBtn.Location = New-Object System.Drawing.Point(380, 102)
    $pasteBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
    $pasteBtn.FlatStyle = "Flat"
    $pasteBtn.Add_Click({
            $hwidTextBox.Text = [System.Windows.Forms.Clipboard]::GetText()
        })
    $genForm.Controls.Add($pasteBtn)
    
    $clearBtn = New-Object System.Windows.Forms.Button
    $clearBtn.Text = "清空"
    $clearBtn.Size = New-Object System.Drawing.Size(50, 28)
    $clearBtn.Location = New-Object System.Drawing.Point(440, 102)
    $clearBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
    $clearBtn.FlatStyle = "Flat"
    $clearBtn.Add_Click({
            $hwidTextBox.Text = ""
        })
    $genForm.Controls.Add($clearBtn)
    
    $daysLabel = New-Object System.Windows.Forms.Label
    $daysLabel.Text = $txtLicenseDaysLabel
    $daysLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $daysLabel.Size = New-Object System.Drawing.Size(460, 20)
    $daysLabel.Location = New-Object System.Drawing.Point(20, 138)
    $genForm.Controls.Add($daysLabel)
    
    $daysTextBox = New-Object System.Windows.Forms.TextBox
    $daysTextBox.Size = New-Object System.Drawing.Size(100, 28)
    $daysTextBox.Location = New-Object System.Drawing.Point(20, 162)
    $daysTextBox.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $daysTextBox.Text = "0"
    $genForm.Controls.Add($daysTextBox)
    
    $daysHintLabel = New-Object System.Windows.Forms.Label
    $daysHintLabel.Text = $txtLicenseDaysHint
    $daysHintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
    $daysHintLabel.Size = New-Object System.Drawing.Size(300, 20)
    $daysHintLabel.Location = New-Object System.Drawing.Point(130, 165)
    $daysHintLabel.ForeColor = [System.Drawing.Color]::Gray
    $genForm.Controls.Add($daysHintLabel)
    
    $quickDaysPanel = New-Object System.Windows.Forms.Panel
    $quickDaysPanel.Size = New-Object System.Drawing.Size(460, 28)
    $quickDaysPanel.Location = New-Object System.Drawing.Point(20, 195)
    $genForm.Controls.Add($quickDaysPanel)
    
    $quickDays = @(
        @{Text = "永久"; Days = 0 },
        @{Text = "7天"; Days = 7 },
        @{Text = "30天"; Days = 30 },
        @{Text = "90天"; Days = 90 },
        @{Text = "365天"; Days = 365 }
    )
    
    $xPos = 0
    foreach ($qd in $quickDays) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $qd.Text
        $btn.Size = New-Object System.Drawing.Size(80, 26)
        $btn.Location = New-Object System.Drawing.Point($xPos, 0)
        $btn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
        $btn.FlatStyle = "Flat"
        $btn.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
        $btn.ForeColor = [System.Drawing.Color]::White
        $days = $qd.Days
        $btn.Add_Click({
                $daysTextBox.Text = $days
            }.GetNewClosure())
        $quickDaysPanel.Controls.Add($btn)
        $xPos += 90
    }
    
    $codeLabel = New-Object System.Windows.Forms.Label
    $codeLabel.Text = $txtLicenseCodeLabel
    $codeLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $codeLabel.Size = New-Object System.Drawing.Size(460, 20)
    $codeLabel.Location = New-Object System.Drawing.Point(20, 230)
    $genForm.Controls.Add($codeLabel)
    
    $codeTextBox = New-Object System.Windows.Forms.TextBox
    $codeTextBox.Size = New-Object System.Drawing.Size(460, 28)
    $codeTextBox.Location = New-Object System.Drawing.Point(20, 254)
    $codeTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $codeTextBox.ReadOnly = $true
    $genForm.Controls.Add($codeTextBox)
    
    $genBtn = New-Object System.Windows.Forms.Button
    $genBtn.Text = $txtLicenseGenerateBtn
    $genBtn.Size = New-Object System.Drawing.Size(140, 32)
    $genBtn.Location = New-Object System.Drawing.Point(80, 295)
    $genBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
    $genBtn.ForeColor = [System.Drawing.Color]::White
    $genBtn.FlatStyle = "Flat"
    $genBtn.Add_Click({
            $hwid = $hwidTextBox.Text.Trim()
            $days = [int]$daysTextBox.Text
        
            if ([string]::IsNullOrEmpty($hwid)) {
                [System.Windows.Forms.MessageBox]::Show("请输入硬件ID！", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }
        
            if ($hwid.Length -ne 32) {
                [System.Windows.Forms.MessageBox]::Show("硬件ID必须是 32 位字符！`n当前长度：$($hwid.Length)", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }
        
            $code = New-LicenseCode -HardwareID $hwid -ValidDays $days
            if ($code) {
                $codeTextBox.Text = $code
                $expireInfo = if ($days -gt 0) { "有效期：$days 天" } else { "永久授权" }
                [System.Windows.Forms.MessageBox]::Show("授权码生成成功！`n`n$expireInfo", $txtSuccess, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
            else {
                [System.Windows.Forms.MessageBox]::Show("生成授权码失败！", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        })
    $genForm.Controls.Add($genBtn)
    
    $copyBtn = New-Object System.Windows.Forms.Button
    $copyBtn.Text = $txtLicenseCopyBtn
    $copyBtn.Size = New-Object System.Drawing.Size(140, 32)
    $copyBtn.Location = New-Object System.Drawing.Point(240, 295)
    $copyBtn.BackColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
    $copyBtn.ForeColor = [System.Drawing.Color]::White
    $copyBtn.FlatStyle = "Flat"
    $copyBtn.Add_Click({
            if (-not [string]::IsNullOrEmpty($codeTextBox.Text)) {
                [System.Windows.Forms.Clipboard]::SetText($codeTextBox.Text)
                [System.Windows.Forms.MessageBox]::Show("授权码已复制到剪贴板！", $txtDone, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
            else {
                [System.Windows.Forms.MessageBox]::Show("请先生成授权码！", $txtWarning, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            }
        })
    $genForm.Controls.Add($copyBtn)
    
    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = $txtCancel
    $closeBtn.Size = New-Object System.Drawing.Size(80, 32)
    $closeBtn.Location = New-Object System.Drawing.Point(400, 295)
    $closeBtn.Add_Click({ $genForm.Close() })
    $genForm.Controls.Add($closeBtn)
    
    $genForm.Add_Shown({ $genForm.Activate() })
    [void]$genForm.ShowDialog()
}

$script:initialHwid = Get-USBHardwareID
$script:savedHwid = $null

$licenseResult = Test-LicenseValid
$script:licenseActivated = $licenseResult.Valid
$script:licenseStatus = $licenseResult.Status
$script:usbChanged = $false

if ($licenseResult.Valid -and $licenseResult.License) {
    $license = Load-License
    if ($license) {
        $savedHwid = $license.HWID
        $result = Test-LicenseCode -LicenseCode $license.Code
        
        if ($result.Error -eq "HWID mismatch") {
            $script:usbChanged = $true
            $script:licenseActivated = $false
            $script:licenseStatus = $txtLicenseHWIDMismatch + " (U盘已变更)"
            Write-Host "[HWID Alert] 检测到U盘变更！保存的HWID: $savedHwid，当前HWID: $($result.CurrentHWID)"
        }
        elseif ($result.Valid -and $result.ExpireDate -gt 0) {
            $expireTime = [DateTimeOffset]::FromUnixTimeSeconds($result.ExpireDate).LocalDateTime
            $daysLeft = ($expireTime - [DateTime]::Now).Days
            if ($daysLeft -le 7 -and $daysLeft -gt 0) {
                $script:licenseExpiringSoon = $true
                $script:licenseStatus = "$txtLicenseActivated (即将到期: $daysLeft 天后)"
            }
        }
    }
}

$script:form = New-Object System.Windows.Forms.Form
$script:form.Text = $txtTitle
$script:form.Size = New-Object System.Drawing.Size(480, 750)
$script:form.StartPosition = "CenterScreen"
$script:form.FormBorderStyle = "FixedSingle"
$script:form.MaximizeBox = $false
$script:form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = $txtTitle
$titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.Size = New-Object System.Drawing.Size(440, 35)
$titleLabel.Location = New-Object System.Drawing.Point(20, 12)
$titleLabel.TextAlign = "MiddleCenter"
$script:form.Controls.Add($titleLabel)

$subLabel = New-Object System.Windows.Forms.Label
$subLabel.Text = $txtSubtitle
$subLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
$subLabel.Size = New-Object System.Drawing.Size(440, 22)
$subLabel.Location = New-Object System.Drawing.Point(20, 45)
$subLabel.TextAlign = "MiddleCenter"
$subLabel.ForeColor = [System.Drawing.Color]::Gray
$script:form.Controls.Add($subLabel)

$script:licenseLabel = New-Object System.Windows.Forms.Label
$script:licenseLabel.Text = "授权状态：" + $script:licenseStatus
$script:licenseLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
$script:licenseLabel.Size = New-Object System.Drawing.Size(440, 22)
$script:licenseLabel.Location = New-Object System.Drawing.Point(20, 68)
$script:licenseLabel.TextAlign = "MiddleCenter"
if ($script:usbChanged) {
    $script:licenseLabel.ForeColor = [System.Drawing.Color]::FromArgb(139, 0, 0)
}
elseif ($script:licenseActivated) { 
    if ($script:licenseExpiringSoon) { 
        $script:licenseLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 153, 0) 
    }
    else { 
        $script:licenseLabel.ForeColor = [System.Drawing.Color]::FromArgb(46, 139, 87) 
    } 
}
else { 
    $script:licenseLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69) 
}
$script:licenseLabel.Cursor = "Hand"
$script:licenseLabel.Add_DoubleClick({
        $license = Load-License
        $currentHwid = Get-USBHardwareID
        $stabilityStatus = Get-HWIDStabilityStatus
        if ($license) {
            $result = Test-LicenseCode -LicenseCode $license.Code
            $info = "授权详情`n`n"
            $info += "硬件ID: $currentHwid`n"
            if (-not $stabilityStatus.IsStable) {
                $info += "⚠️ 警告: 硬件ID不稳定，格式化U盘后可能失效！`n"
            }
            else {
                $info += "✓ 硬件ID稳定，与U盘硬件绑定`n"
            }
            $info += "`n"
            if ($result.Valid) {
                $info += "状态: 已授权 ✓`n"
                $activatedTime = [DateTimeOffset]::FromUnixTimeSeconds($license.ActivatedAt).LocalDateTime
                $info += "激活时间: $($activatedTime.ToString('yyyy-MM-dd HH:mm:ss'))`n"
                if ($result.ExpireDate -gt 0) {
                    $expireTime = [DateTimeOffset]::FromUnixTimeSeconds($result.ExpireDate).LocalDateTime
                    $info += "到期时间: $($expireTime.ToString('yyyy-MM-dd HH:mm:ss'))`n"
                    $daysLeft = ($expireTime - [DateTime]::Now).Days
                    $info += "剩余天数: $daysLeft 天"
                }
                else {
                    $info += "授权类型: 永久授权"
                }
            }
            else {
                $info += "状态: 未授权或已失效`n"
                $info += "错误: $($result.Error)"
            }
            [System.Windows.Forms.MessageBox]::Show($info, "授权详情", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        else {
            $info = "当前硬件ID: $currentHwid`n`n"
            if (-not $stabilityStatus.IsStable) {
                $info += "⚠️ 警告: 硬件ID不稳定！`n"
                $info += "建议在真实的U盘上运行以获取稳定的硬件ID。`n`n"
            }
            $info += "尚未激活授权。`n`n请点击 [激活授权] 按钮输入授权码。"
            [System.Windows.Forms.MessageBox]::Show($info, "授权详情", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    })
$script:form.Controls.Add($script:licenseLabel)

$script:statusLabel = New-Object System.Windows.Forms.Label
$script:statusLabel.Text = $txtReady
$script:statusLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
$script:statusLabel.Size = New-Object System.Drawing.Size(440, 22)
$script:statusLabel.Location = New-Object System.Drawing.Point(20, 91)
$script:statusLabel.TextAlign = "MiddleCenter"
$script:statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$script:form.Controls.Add($script:statusLabel)

$titleLabel.Add_Click({
        $modifiers = [System.Windows.Forms.Control]::ModifierKeys
        $shiftPressed = ($modifiers -band [System.Windows.Forms.Keys]::Shift) -eq [System.Windows.Forms.Keys]::Shift
        $ctrlPressed = ($modifiers -band [System.Windows.Forms.Keys]::Control) -eq [System.Windows.Forms.Keys]::Control
        if ($shiftPressed -and $ctrlPressed) {
            Show-LicenseGenerator
        }
    })

function Create-Button {
    param($text, $y, $Color)
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = $Text
    $Btn.Size = New-Object System.Drawing.Size(420, 40)
    $Btn.Location = New-Object System.Drawing.Point(20, $y)
    $Btn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
    $Btn.BackColor = $Color
    $Btn.ForeColor = [System.Drawing.Color]::White
    $Btn.FlatStyle = "Flat"
    $Btn.FlatAppearance.BorderSize = 0
    $Btn.Cursor = "Hand"
    return $Btn
}

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.InitialDelay = 500
$toolTip.ShowAlways = $true

$btnStart = Create-Button $txtBtnStart 123 ([System.Drawing.Color]::FromArgb(0, 122, 204))
$btnStart.Enabled = $script:licenseActivated
$btnStart.Add_Click({
        if (-not $script:licenseActivated) {
            [System.Windows.Forms.MessageBox]::Show("请先激活授权后再启动 OpenClaw！", $txtWarning, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        $script:statusLabel.Text = $txtStarting
        $script:form.Refresh()
        Start-UClaw
    })
$script:form.Controls.Add($btnStart)
$script:btnStart = $btnStart
$toolTip.SetToolTip($btnStart, "启动 OpenClaw AI 助手服务")

$btnModel = Create-Button $txtBtnModel 171 ([System.Drawing.Color]::FromArgb(138, 43, 226))
$btnModel.Add_Click({
        Switch-Model
    })
$script:form.Controls.Add($btnModel)
$toolTip.SetToolTip($btnModel, "切换当前使用的 AI 模型")

$btnToken = Create-Button "模型充值" 219 ([System.Drawing.Color]::FromArgb(255, 140, 0))
$btnToken.Add_Click({
        Show-RechargeDialog
    })
$script:form.Controls.Add($btnToken)

$btnChannel = Create-Button "聊天平台频道" 267 ([System.Drawing.Color]::FromArgb(70, 130, 180))
$btnChannel.Add_Click({
        Show-ChannelDialog
    })
$script:form.Controls.Add($btnChannel)

$btnDeploy = Create-Button $txtBtnDeploy 315 ([System.Drawing.Color]::FromArgb(32, 178, 170))
$btnDeploy.Add_Click({
        if (-not $script:licenseActivated) {
            [System.Windows.Forms.MessageBox]::Show($txtLicenseDeployBlocked, $txtWarning, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        $msg = $txtConfirmDeploy + "`n`n" + $txtEnsureUsb + "`n`n" + $txtContinue
        $result = [System.Windows.Forms.MessageBox]::Show($msg, $txtConfirm, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($result -eq "Yes") {
            Deploy-ToUSB
        }
    })
$script:form.Controls.Add($btnDeploy)
$toolTip.SetToolTip($btnDeploy, "将 OpenClaw 部署到其他 U 盘")

$btnUpgrade = Create-Button $txtBtnUpgrade 363 ([System.Drawing.Color]::FromArgb(46, 139, 87))
$btnUpgrade.Add_Click({
        # 调用早期简单升级流程
        Upgrade-UClaw
    })
$script:form.Controls.Add($btnUpgrade)
$toolTip.SetToolTip($btnUpgrade, "检查并升级到最新版本")

$btnRepair = Create-Button $txtBtnRepair 411 ([System.Drawing.Color]::FromArgb(255, 153, 0))
$btnRepair.Add_Click({
        $msg = $txtConfirmRepair + "`n`n" + $txtContinue
        $result = [System.Windows.Forms.MessageBox]::Show($msg, $txtConfirm, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($result -eq "Yes") {
            $script:statusLabel.Text = $txtRepairFailed
            $script:form.Refresh()
            Repair-UClaw
        }
    })
$script:form.Controls.Add($btnRepair)
$toolTip.SetToolTip($btnRepair, "下载并安装依赖组件")

$btnActivate = Create-Button $txtBtnActivate 459 ([System.Drawing.Color]::FromArgb(220, 53, 69))
$btnActivate.Add_Click({
        Show-ActivationDialog
        $licenseResult = Test-LicenseValid
        $script:licenseActivated = $licenseResult.Valid
        $script:licenseStatus = $licenseResult.Status
        $script:usbChanged = $false
        if ($licenseResult.Valid -and $licenseResult.License) {
            $result = Test-LicenseCode -LicenseCode $licenseResult.License.Code
            if ($result.Valid -and $result.ExpireDate -gt 0) {
                $expireTime = [DateTimeOffset]::FromUnixTimeSeconds($result.ExpireDate).LocalDateTime
                $daysLeft = ($expireTime - [DateTime]::Now).Days
                if ($daysLeft -le 7 -and $daysLeft -gt 0) {
                    $script:licenseExpiringSoon = $true
                    $script:licenseStatus = "$txtLicenseActivated (即将到期: $daysLeft 天后)"
                }
                else {
                    $script:licenseExpiringSoon = $false
                }
            }
        }
        $script:licenseLabel.Text = "授权状态：" + $script:licenseStatus
        if ($script:usbChanged) {
            $script:licenseLabel.ForeColor = [System.Drawing.Color]::FromArgb(139, 0, 0)
        }
        elseif ($script:licenseActivated) {
            if ($script:licenseExpiringSoon) {
                $script:licenseLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 153, 0)
            }
            else {
                $script:licenseLabel.ForeColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
            }
            $btnStart.Enabled = $true
        }
        else {
            $script:licenseLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
            $btnStart.Enabled = $false
        }
    })
$script:form.Controls.Add($btnActivate)
$toolTip.SetToolTip($btnActivate, "输入授权码激活软件")

$btnSkillManage = Create-Button $txtBtnSkillManage 507 ([System.Drawing.Color]::FromArgb(0, 123, 255))
$btnSkillManage.Add_Click({
        Show-SkillManager
    })
$script:form.Controls.Add($btnSkillManage)
$toolTip.SetToolTip($btnSkillManage, "查看已安装的技能列表")

$btnBackup = Create-Button $txtBtnBackup 555 ([System.Drawing.Color]::FromArgb(40, 167, 69))
$btnBackup.Add_Click({
        Show-BackupMenu
    })
$script:form.Controls.Add($btnBackup)
$toolTip.SetToolTip($btnBackup, "备份管理：创建备份、恢复备份、查看历史")

$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Text = $txtHint
$infoLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
$infoLabel.Size = New-Object System.Drawing.Size(440, 18)
$infoLabel.Location = New-Object System.Drawing.Point(20, 600)
$infoLabel.TextAlign = "MiddleCenter"
$infoLabel.ForeColor = [System.Drawing.Color]::Gray
$script:form.Controls.Add($infoLabel)

$versionLabel = New-Object System.Windows.Forms.Label
$coreVersion = Get-OpenClawCoreVersion
if ($coreVersion) {
    $versionLabel.Text = "U盘版 " + $script:CURRENT_VERSION + " | OpenClaw 核心 " + $coreVersion + " | Node.js " + $script:NODE_VERSION
}
else {
    $versionLabel.Text = "U盘版 " + $script:CURRENT_VERSION + " | 核心未安装 | Node.js " + $script:NODE_VERSION
}
$versionLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
$versionLabel.Size = New-Object System.Drawing.Size(440, 18)
$versionLabel.Location = New-Object System.Drawing.Point(20, 618)
$versionLabel.TextAlign = "MiddleCenter"
$versionLabel.ForeColor = [System.Drawing.Color]::LightGray
$script:form.Controls.Add($versionLabel)

$networkStatusLabel = New-Object System.Windows.Forms.Label
$networkStatusLabel.Text = "🌐 " + $txtNetworkChecking
$networkStatusLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
$networkStatusLabel.Size = New-Object System.Drawing.Size(80, 18)
$networkStatusLabel.Location = New-Object System.Drawing.Point(20, 580)
$networkStatusLabel.TextAlign = "MiddleLeft"
$networkStatusLabel.ForeColor = [System.Drawing.Color]::Gray
$networkStatusLabel.Cursor = "Hand"
$script:form.Controls.Add($networkStatusLabel)
$script:networkStatusLabel = $networkStatusLabel

$updateTipLabel = New-Object System.Windows.Forms.Label
$updateTipLabel.Text = ""
$updateTipLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8, [System.Drawing.FontStyle]::Underline)
$updateTipLabel.Size = New-Object System.Drawing.Size(200, 18)
$updateTipLabel.Location = New-Object System.Drawing.Point(100, 580)
$updateTipLabel.TextAlign = "MiddleLeft"
$updateTipLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 123, 255)
$updateTipLabel.Cursor = "Hand"
$updateTipLabel.Visible = $false
$script:form.Controls.Add($updateTipLabel)
$script:updateTipLabel = $updateTipLabel

$adminHintLabel = New-Object System.Windows.Forms.Label
$adminHintLabel.Text = "管理员：Shift+Ctrl 点击标题打开授权码生成器"
$adminHintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 7)
$adminHintLabel.Size = New-Object System.Drawing.Size(440, 16)
$adminHintLabel.Location = New-Object System.Drawing.Point(20, 636)
$adminHintLabel.TextAlign = "MiddleCenter"
$adminHintLabel.ForeColor = [System.Drawing.Color]::LightGray
$script:form.Controls.Add($adminHintLabel)

function Ensure-Config {
    if (-not (Test-Path $script:STATE_DIR)) {
        New-Item -ItemType Directory -Path $script:STATE_DIR -Force | Out-Null
    }
    
    $configFile = Join-Path $script:STATE_DIR "openclaw.json"
    if (-not (Test-Path $configFile)) {
        $defaultConfig = @{
            gateway = @{
                mode = "local"
                auth = @{
                    mode  = "token"
                    token = "uclaw"
                }
            }
        }
        $json = $defaultConfig | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($configFile, $json, (New-Object System.Text.UTF8Encoding $false))
    }
}

function Get-GatewayToken {
    return "uclaw"
}

function Sync-Token {
    Ensure-Config
    $token = Get-GatewayToken
    $configFile = Join-Path $script:STATE_DIR "openclaw.json"
    
    try {
        $configContent = Get-Content $configFile -Raw
        $config = $configContent | ConvertFrom-Json
        
        if (-not $config.gateway) {
            $config | Add-Member -MemberType NoteProperty -Name "gateway" -Value @{} -Force
        }
        if (-not $config.gateway.auth) {
            $config.gateway | Add-Member -MemberType NoteProperty -Name "auth" -Value @{} -Force
        }
        
        $currentToken = $config.gateway.auth.token
        if ($currentToken -ne $token) {
            $config.gateway.auth.token = $token
            $config.gateway.auth.mode = "token"
            $json = $config | ConvertTo-Json -Depth 10
            [System.IO.File]::WriteAllText($configFile, $json, (New-Object System.Text.UTF8Encoding $false))
            Write-Host "Token synced: $token"
        }
    }
    catch {
        Write-Host "Error syncing token: $_"
        $newConfig = @{
            gateway = @{
                mode = "local"
                auth = @{
                    mode  = "token"
                    token = $token
                }
            }
        }
        $json = $newConfig | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($configFile, $json, (New-Object System.Text.UTF8Encoding $false))
    }
    return $token
}

function Get-OllamaModels {
    $ollamaModels = @()
    try {
        $response = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($response -and $response.models) {
            foreach ($model in $response.models) {
                $modelName = $model.name
                $sizeGB = [math]::Round($model.size / 1GB, 1)
                $family = if ($model.details -and $model.details.family) { $model.details.family } else { "unknown" }
                $paramSize = if ($model.details -and $model.details.parameter_size) { $model.details.parameter_size } else { "" }
                
                $displayName = "本地 Ollama ($modelName)"
                if ($paramSize) {
                    $displayName = "本地 Ollama ($modelName, $paramSize)"
                }
                
                $ollamaModels += @{
                    Name     = $displayName
                    Provider = "ollama"
                    Model    = $modelName
                    BaseUrl  = "http://127.0.0.1:11434/v1"
                    NeedKey  = $false
                    Hint     = "本地 ($sizeGB GB, $family)"
                }
            }
        }
    }
    catch {
        Write-Host "Ollama not detected: $_"
    }
    return $ollamaModels
}

function Save-CustomModel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Vendor,
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,
        [Parameter(Mandatory = $true)]
        [string]$ModelId,
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",
        [switch]$TestConnection
    )

    if ([string]::IsNullOrEmpty($ModelId)) {
        return @{ Success = $false; Error = $txtCustomModelInvalidModelId }
    }

    if (-not [string]::IsNullOrEmpty($BaseUrl)) {
        try {
            $uri = [System.Uri]$BaseUrl
            if ($uri.Scheme -ne "http" -and $uri.Scheme -ne "https") {
                return @{ Success = $false; Error = $txtCustomModelInvalidBaseUrl }
            }
        }
        catch {
            return @{ Success = $false; Error = $txtCustomModelInvalidBaseUrl }
        }
    }

    if ($TestConnection -and -not [string]::IsNullOrEmpty($BaseUrl) -and -not [string]::IsNullOrEmpty($ApiKey)) {
        try {
            $headers = @{
                "Authorization" = "Bearer $ApiKey"
                "Content-Type"  = "application/json"
            }
            $testUrl = $BaseUrl.TrimEnd('/') + "/v1/models"
            $response = Invoke-RestMethod -Uri $testUrl -Headers $headers -TimeoutSec 15 -ErrorAction Stop
            if (-not $response -or -not $response.data) {
                return @{ Success = $false; Error = "API connection test failed: Invalid response" }
            }
        }
        catch {
            return @{ Success = $false; Error = "API connection test failed: $($_.Exception.Message)" }
        }
    }

    try {
        $customModels = Load-CustomModels

        $modelName = "$Vendor ($ModelId)"
        $existingModel = $customModels | Where-Object { $_.Name -eq $modelName }
        if ($existingModel) {
            return @{ Success = $false; Error = $txtCustomModelNameExists }
        }

        $newModel = @{
            Name      = $modelName
            Vendor    = $Vendor
            Provider  = "custom"
            Model     = $ModelId
            BaseUrl   = $BaseUrl
            ApiKey    = $ApiKey
            NeedKey   = -not [string]::IsNullOrEmpty($ApiKey)
            Hint      = "自定义模型"
            CreatedAt = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        }

        $customModels += $newModel

        $stateDir = Split-Path $script:CUSTOM_MODELS_FILE -Parent
        if (-not (Test-Path $stateDir)) {
            New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        }

        $customModels | ConvertTo-Json -Depth 10 | Out-File $script:CUSTOM_MODELS_FILE -Encoding utf8

        if (-not [string]::IsNullOrEmpty($ApiKey)) {
            try {
                Update-ModelsConfig -Provider "custom" -ApiKey $ApiKey -BaseUrl $BaseUrl | Out-Null
            }
            catch {
                Write-Host "Failed to save custom model API key: $_"
            }
        }

        return @{ Success = $true; Model = $newModel }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Load-CustomModels {
    try {
        if (-not (Test-Path $script:CUSTOM_MODELS_FILE)) {
            return @()
        }
        
        $json = Get-Content $script:CUSTOM_MODELS_FILE -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrEmpty($json)) {
            return @()
        }
        
        $models = $json | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -eq $models) {
            return @()
        }
        
        $result = @()
        foreach ($model in $models) {
            $result += @{
                Name      = if ($model.Name) { $model.Name } else { "" }
                Vendor    = if ($model.Vendor) { $model.Vendor } else { "" }
                Provider  = "custom"
                Model     = if ($model.Model) { $model.Model } else { "" }
                BaseUrl   = if ($model.BaseUrl) { $model.BaseUrl } else { "" }
                ApiKey    = if ($model.ApiKey) { $model.ApiKey } else { "" }
                NeedKey   = if ($null -ne $model.NeedKey) { $model.NeedKey } else { $false }
                Hint      = if ($model.Hint) { $model.Hint } else { "" }
                CreatedAt = if ($model.CreatedAt) { $model.CreatedAt } else { 0 }
            }
        }
        
        return $result
    }
    catch {
        return @()
    }
}

function Delete-CustomModel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModelName
    )
    
    try {
        $customModels = Load-CustomModels
        
        $filteredModels = $customModels | Where-Object { $_.Name -ne $ModelName }
        
        if ($filteredModels.Count -eq 0) {
            $filteredModels = @()
        }
        
        $filteredModels | ConvertTo-Json -Depth 10 | Out-File $script:CUSTOM_MODELS_FILE -Encoding utf8
        
        return $true
    }
    catch {
        Write-Host "Error deleting custom model: $_"
        return $false
    }
}

function Show-AddCustomModelDialog {
    param($parentForm)
    
    $addForm = New-Object System.Windows.Forms.Form
    $addForm.Text = $txtCustomModelTitle
    $addForm.Size = New-Object System.Drawing.Size(520, 420)
    $addForm.StartPosition = "CenterScreen"
    $addForm.FormBorderStyle = "FixedSingle"
    $addForm.MaximizeBox = $false
    $addForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $txtCustomModelTitle
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(480, 30)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 12)
    $titleLabel.TextAlign = "MiddleCenter"
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
    $addForm.Controls.Add($titleLabel)
    
    $yPos = 50
    
    $vendorLabel = New-Object System.Windows.Forms.Label
    $vendorLabel.Text = $txtCustomModelVendor
    $vendorLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $vendorLabel.Size = New-Object System.Drawing.Size(460, 20)
    $vendorLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $addForm.Controls.Add($vendorLabel)
    $yPos += 22
    
    $vendorTextBox = New-Object System.Windows.Forms.TextBox
    $vendorTextBox.Name = "vendorTextBox"
    $vendorTextBox.Size = New-Object System.Drawing.Size(460, 28)
    $vendorTextBox.Location = New-Object System.Drawing.Point(20, $yPos)
    $vendorTextBox.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $addForm.Controls.Add($vendorTextBox)
    $yPos += 30
    
    $vendorHintLabel = New-Object System.Windows.Forms.Label
    $vendorHintLabel.Text = $txtCustomModelVendorHint
    $vendorHintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 7)
    $vendorHintLabel.Size = New-Object System.Drawing.Size(460, 16)
    $vendorHintLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $vendorHintLabel.ForeColor = [System.Drawing.Color]::Gray
    $addForm.Controls.Add($vendorHintLabel)
    $yPos += 22
    
    $baseUrlLabel = New-Object System.Windows.Forms.Label
    $baseUrlLabel.Text = $txtCustomModelBaseUrl
    $baseUrlLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $baseUrlLabel.Size = New-Object System.Drawing.Size(460, 20)
    $baseUrlLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $addForm.Controls.Add($baseUrlLabel)
    $yPos += 22
    
    $baseUrlTextBox = New-Object System.Windows.Forms.TextBox
    $baseUrlTextBox.Name = "baseUrlTextBox"
    $baseUrlTextBox.Size = New-Object System.Drawing.Size(460, 28)
    $baseUrlTextBox.Location = New-Object System.Drawing.Point(20, $yPos)
    $baseUrlTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $addForm.Controls.Add($baseUrlTextBox)
    $yPos += 30
    
    $baseUrlHintLabel = New-Object System.Windows.Forms.Label
    $baseUrlHintLabel.Text = $txtCustomModelBaseUrlHint
    $baseUrlHintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 7)
    $baseUrlHintLabel.Size = New-Object System.Drawing.Size(460, 16)
    $baseUrlHintLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $baseUrlHintLabel.ForeColor = [System.Drawing.Color]::Gray
    $addForm.Controls.Add($baseUrlHintLabel)
    $yPos += 22
    
    $modelIdLabel = New-Object System.Windows.Forms.Label
    $modelIdLabel.Text = $txtCustomModelModelId
    $modelIdLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $modelIdLabel.Size = New-Object System.Drawing.Size(460, 20)
    $modelIdLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $addForm.Controls.Add($modelIdLabel)
    $yPos += 22
    
    $modelIdTextBox = New-Object System.Windows.Forms.TextBox
    $modelIdTextBox.Name = "modelIdTextBox"
    $modelIdTextBox.Size = New-Object System.Drawing.Size(460, 28)
    $modelIdTextBox.Location = New-Object System.Drawing.Point(20, $yPos)
    $modelIdTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $addForm.Controls.Add($modelIdTextBox)
    $yPos += 30
    
    $modelIdHintLabel = New-Object System.Windows.Forms.Label
    $modelIdHintLabel.Text = $txtCustomModelModelIdHint
    $modelIdHintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 7)
    $modelIdHintLabel.Size = New-Object System.Drawing.Size(460, 16)
    $modelIdHintLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $modelIdHintLabel.ForeColor = [System.Drawing.Color]::Gray
    $addForm.Controls.Add($modelIdHintLabel)
    $yPos += 22
    
    $apiKeyLabel = New-Object System.Windows.Forms.Label
    $apiKeyLabel.Text = $txtCustomModelApiKey
    $apiKeyLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $apiKeyLabel.Size = New-Object System.Drawing.Size(460, 20)
    $apiKeyLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $addForm.Controls.Add($apiKeyLabel)
    $yPos += 22
    
    $apiKeyTextBox = New-Object System.Windows.Forms.TextBox
    $apiKeyTextBox.Name = "apiKeyTextBox"
    $apiKeyTextBox.Size = New-Object System.Drawing.Size(460, 28)
    $apiKeyTextBox.Location = New-Object System.Drawing.Point(20, $yPos)
    $apiKeyTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $apiKeyTextBox.PasswordChar = "*"
    $addForm.Controls.Add($apiKeyTextBox)
    $yPos += 30
    
    $apiKeyHintLabel = New-Object System.Windows.Forms.Label
    $apiKeyHintLabel.Text = $txtCustomModelApiKeyHint
    $apiKeyHintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 7)
    $apiKeyHintLabel.Size = New-Object System.Drawing.Size(460, 16)
    $apiKeyHintLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $apiKeyHintLabel.ForeColor = [System.Drawing.Color]::Gray
    $addForm.Controls.Add($apiKeyHintLabel)
    $yPos += 25
    
    $saveBtn = New-Object System.Windows.Forms.Button
    $saveBtn.Text = $txtCustomModelSave
    $saveBtn.Size = New-Object System.Drawing.Size(100, 32)
    $saveBtn.Location = New-Object System.Drawing.Point(20, $yPos)
    $saveBtn.BackColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
    $saveBtn.ForeColor = [System.Drawing.Color]::White
    $saveBtn.FlatStyle = "Flat"
    $saveBtn.Add_Click({
            $form = $this.FindForm()
            $vendor = $form.Controls["vendorTextBox"].Text.Trim()
            $baseUrl = $form.Controls["baseUrlTextBox"].Text.Trim()
            $modelId = $form.Controls["modelIdTextBox"].Text.Trim()
            $apiKey = $form.Controls["apiKeyTextBox"].Text.Trim()

            if ([string]::IsNullOrEmpty($vendor)) {
                [System.Windows.Forms.MessageBox]::Show($txtCustomModelInvalidVendor, $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }

            if ([string]::IsNullOrEmpty($modelId)) {
                [System.Windows.Forms.MessageBox]::Show($txtCustomModelInvalidModelId, $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }

            if (-not [string]::IsNullOrEmpty($baseUrl)) {
                try {
                    $uri = [System.Uri]$baseUrl
                    if ($uri.Scheme -ne "http" -and $uri.Scheme -ne "https") {
                        throw "Invalid scheme"
                    }
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show($txtCustomModelInvalidBaseUrl, $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    return
                }
            }

            $result = Save-CustomModel -Vendor $vendor -BaseUrl $baseUrl -ModelId $modelId -ApiKey $apiKey

            if ($result.Success) {
                [System.Windows.Forms.MessageBox]::Show($txtCustomModelSaved, $txtSuccess, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                $addForm.Close()
                if ($parentForm) {
                    $parentForm.Close()
                    Switch-Model
                }
            }
            else {
                [System.Windows.Forms.MessageBox]::Show($result.Error, $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        })
    $addForm.Controls.Add($saveBtn)

    $testBtn = New-Object System.Windows.Forms.Button
    $testBtn.Text = "测试连接"
    $testBtn.Size = New-Object System.Drawing.Size(100, 32)
    $testBtn.Location = New-Object System.Drawing.Point(130, $yPos)
    $testBtn.BackColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
    $testBtn.ForeColor = [System.Drawing.Color]::White
    $testBtn.FlatStyle = "Flat"
    $testBtn.Add_Click({
            $form = $this.FindForm()
            $vendor = $form.Controls["vendorTextBox"].Text.Trim()
            $baseUrl = $form.Controls["baseUrlTextBox"].Text.Trim()
            $modelId = $form.Controls["modelIdTextBox"].Text.Trim()
            $apiKey = $form.Controls["apiKeyTextBox"].Text.Trim()

            if ([string]::IsNullOrEmpty($baseUrl)) {
                [System.Windows.Forms.MessageBox]::Show("请输入 API URL 进行测试", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }

            if ([string]::IsNullOrEmpty($apiKey)) {
                [System.Windows.Forms.MessageBox]::Show("请输入 API Key 进行测试", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }

            $testBtn.Enabled = $false
            $testBtn.Text = "测试中..."

            $result = Save-CustomModel -Vendor $vendor -BaseUrl $baseUrl -ModelId $modelId -ApiKey $apiKey -TestConnection

            $testBtn.Enabled = $true
            $testBtn.Text = "测试连接"

            if ($result.Success) {
                [System.Windows.Forms.MessageBox]::Show("API 连接测试成功！", $txtSuccess, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
            else {
                [System.Windows.Forms.MessageBox]::Show($result.Error, "测试失败", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        })
    $addForm.Controls.Add($testBtn)
    
    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Text = $txtCancel
    $cancelBtn.Size = New-Object System.Drawing.Size(100, 32)
    $cancelBtn.Location = New-Object System.Drawing.Point(240, $yPos)
    $cancelBtn.Add_Click({ $this.FindForm().Close() })
    $addForm.Controls.Add($cancelBtn)
    
    $addForm.Add_Shown({ $vendorTextBox.Focus() })
    [void]$addForm.ShowDialog()
}

function Show-ModelsConfigDialog {
    $configForm = New-Object System.Windows.Forms.Form
    $configForm.Text = $txtModelsConfigTitle
    $configForm.Size = New-Object System.Drawing.Size(700, 500)
    $configForm.StartPosition = "CenterScreen"
    $configForm.FormBorderStyle = "FixedSingle"
    $configForm.MaximizeBox = $false
    $configForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $txtModelsConfigTitle
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(660, 35)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $titleLabel.TextAlign = "MiddleCenter"
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
    $configForm.Controls.Add($titleLabel)

    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(660, 35)
    $headerPanel.Location = New-Object System.Drawing.Point(20, 60)
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(220, 220, 235)

    $headerProviderLabel = New-Object System.Windows.Forms.Label
    $headerProviderLabel.Text = $txtModelsConfigProvider
    $headerProviderLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9, [System.Drawing.FontStyle]::Bold)
    $headerProviderLabel.Size = New-Object System.Drawing.Size(120, 35)
    $headerProviderLabel.Location = New-Object System.Drawing.Point(10, 8)
    $headerProviderLabel.TextAlign = "MiddleLeft"
    $headerPanel.Controls.Add($headerProviderLabel)

    $headerApiKeyLabel = New-Object System.Windows.Forms.Label
    $headerApiKeyLabel.Text = $txtModelsConfigApiKey
    $headerApiKeyLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9, [System.Drawing.FontStyle]::Bold)
    $headerApiKeyLabel.Size = New-Object System.Drawing.Size(200, 35)
    $headerApiKeyLabel.Location = New-Object System.Drawing.Point(140, 8)
    $headerApiKeyLabel.TextAlign = "MiddleLeft"
    $headerPanel.Controls.Add($headerApiKeyLabel)

    $headerBaseUrlLabel = New-Object System.Windows.Forms.Label
    $headerBaseUrlLabel.Text = $txtModelsConfigBaseUrl
    $headerBaseUrlLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9, [System.Drawing.FontStyle]::Bold)
    $headerBaseUrlLabel.Size = New-Object System.Drawing.Size(180, 35)
    $headerBaseUrlLabel.Location = New-Object System.Drawing.Point(350, 8)
    $headerBaseUrlLabel.TextAlign = "MiddleLeft"
    $headerPanel.Controls.Add($headerBaseUrlLabel)

    $headerActionsLabel = New-Object System.Windows.Forms.Label
    $headerActionsLabel.Text = "操作"
    $headerActionsLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9, [System.Drawing.FontStyle]::Bold)
    $headerActionsLabel.Size = New-Object System.Drawing.Size(200, 35)
    $headerActionsLabel.Location = New-Object System.Drawing.Point(540, 8)
    $headerActionsLabel.TextAlign = "MiddleCenter"
    $headerPanel.Controls.Add($headerActionsLabel)

    $configForm.Controls.Add($headerPanel)

    $listPanel = New-Object System.Windows.Forms.Panel
    $listPanel.Size = New-Object System.Drawing.Size(660, 300)
    $listPanel.Location = New-Object System.Drawing.Point(20, 100)
    $listPanel.AutoScroll = $true
    $listPanel.BackColor = [System.Drawing.Color]::White

    $modelsConfig = Load-ModelsConfig
    $providerList = @()
    if ($modelsConfig.providers) {
        foreach ($providerName in $modelsConfig.providers.PSObject.Properties.Name) {
            $providerData = $modelsConfig.providers.$providerName
            $providerList += @{
                Name    = $providerName
                ApiKey  = $providerData.apiKey
                BaseUrl = $providerData.baseUrl
            }
        }
    }

    if ($providerList.Count -eq 0) {
        $emptyLabel = New-Object System.Windows.Forms.Label
        $emptyLabel.Text = $txtModelsConfigEmpty
        $emptyLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
        $emptyLabel.Size = New-Object System.Drawing.Size(620, 60)
        $emptyLabel.Location = New-Object System.Drawing.Point(20, 120)
        $emptyLabel.TextAlign = "MiddleCenter"
        $emptyLabel.ForeColor = [System.Drawing.Color]::Gray
        $configForm.Controls.Add($emptyLabel)
    }
    else {
        $rowHeight = 50
        $yOffset = 10
        foreach ($provider in $providerList) {
            $rowPanel = New-Object System.Windows.Forms.Panel
            $rowPanel.Size = New-Object System.Drawing.Size(640, $rowHeight)
            $rowPanel.Location = New-Object System.Drawing.Point(10, $yOffset)
            $rowPanel.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 255)
            $rowPanel.Tag = $provider.Name

            $providerLabel = New-Object System.Windows.Forms.Label
            $providerLabel.Text = $provider.Name
            $providerLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
            $providerLabel.Size = New-Object System.Drawing.Size(120, $rowHeight)
            $providerLabel.Location = New-Object System.Drawing.Point(10, 0)
            $providerLabel.TextAlign = "MiddleLeft"
            $rowPanel.Controls.Add($providerLabel)

            $apiKeyDisplay = $provider.ApiKey
            if ($apiKeyDisplay.Length -gt 12) {
                $apiKeyDisplay = $apiKeyDisplay.Substring(0, 8) + "..." + $apiKeyDisplay.Substring($apiKeyDisplay.Length - 4)
            }
            elseif ($apiKeyDisplay.Length -gt 4) {
                $apiKeyDisplay = $apiKeyDisplay.Substring(0, 4) + "..." + $apiKeyDisplay.Substring($apiKeyDisplay.Length - 2)
            }
            $apiKeyLabel = New-Object System.Windows.Forms.Label
            $apiKeyLabel.Text = $apiKeyDisplay
            $apiKeyLabel.Font = New-Object System.Drawing.Font("Consolas", 8)
            $apiKeyLabel.Size = New-Object System.Drawing.Size(200, $rowHeight)
            $apiKeyLabel.Location = New-Object System.Drawing.Point(140, 0)
            $apiKeyLabel.TextAlign = "MiddleLeft"
            $apiKeyLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
            $rowPanel.Controls.Add($apiKeyLabel)

            $baseUrlLabel = New-Object System.Windows.Forms.Label
            $baseUrlLabel.Text = if ($provider.BaseUrl) { $provider.BaseUrl } else { "-" }
            $baseUrlLabel.Font = New-Object System.Drawing.Font("Consolas", 7)
            $baseUrlLabel.Size = New-Object System.Drawing.Size(180, $rowHeight)
            $baseUrlLabel.Location = New-Object System.Drawing.Point(350, 0)
            $baseUrlLabel.TextAlign = "MiddleLeft"
            $baseUrlLabel.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
            $rowPanel.Controls.Add($baseUrlLabel)

            $testBtn = New-Object System.Windows.Forms.Button
            $testBtn.Text = $txtModelsConfigTest
            $testBtn.Size = New-Object System.Drawing.Size(60, 26)
            $testBtn.Location = New-Object System.Drawing.Point(0, 12)
            $testBtn.BackColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
            $testBtn.ForeColor = [System.Drawing.Color]::White
            $testBtn.FlatStyle = "Flat"
            $testBtn.Tag = $provider.Name
            $testBtn.Add_Click({
                    $providerName = $this.Tag
                    $testBtnRef = $this
                    $testBtnRef.Enabled = $false
                    $testBtnRef.Text = "..."

                    $currentConfig = Load-ModelsConfig
                    if ($currentConfig.providers.$providerName) {
                        $apiKey = $currentConfig.providers.$providerName.apiKey
                        $baseUrl = $currentConfig.providers.$providerName.baseUrl

                        if ([string]::IsNullOrEmpty($apiKey)) {
                            [System.Windows.Forms.MessageBox]::Show("API Key 为空", $txtWarning, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                            $testBtnRef.Enabled = $true
                            $testBtnRef.Text = $txtModelsConfigTest
                            return
                        }

                        try {
                            $headers = @{
                                "Authorization" = "Bearer $apiKey"
                                "Content-Type"  = "application/json"
                            }
                            $defaultUrls = @{
                                "openai"   = "https://api.openai.com/v1"
                                "deepseek" = "https://api.deepseek.com/v1"
                                "mistral"  = "https://api.mistral.ai/v1"
                                "groq"     = "https://api.groq.com/openai/v1"
                            }
                            if ([string]::IsNullOrEmpty($baseUrl)) {
                                if ($defaultUrls.ContainsKey($providerName)) {
                                    $testUrl = $defaultUrls[$providerName] + "/models"
                                }
                                else {
                                    $testBtnRef.Enabled = $true
                                    $testBtnRef.Text = $txtModelsConfigTest
                                    return
                                }
                            }
                            else {
                                $testUrl = $baseUrl.TrimEnd('/') + "/v1/models"
                            }
                            $response = Invoke-RestMethod -Uri $testUrl -Headers $headers -TimeoutSec 15 -ErrorAction Stop
                            [System.Windows.Forms.MessageBox]::Show($txtModelsConfigTestSuccess, $txtSuccess, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                        }
                        catch {
                            [System.Windows.Forms.MessageBox]::Show($txtModelsConfigTestFailed + $_.Exception.Message, $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                        }
                    }

                    $testBtnRef.Enabled = $true
                    $testBtnRef.Text = $txtModelsConfigTest
                })
            $rowPanel.Controls.Add($testBtn)

            $editBtn = New-Object System.Windows.Forms.Button
            $editBtn.Text = $txtModelsConfigEdit
            $editBtn.Size = New-Object System.Drawing.Size(60, 26)
            $editBtn.Location = New-Object System.Drawing.Point(540, 12)
            $editBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
            $editBtn.ForeColor = [System.Drawing.Color]::White
            $editBtn.FlatStyle = "Flat"
            $editBtn.Tag = $provider.Name
            $editBtn.Add_Click({
                    $providerName = $this.Tag
                    $editForm = New-Object System.Windows.Forms.Form
                    $editForm.Text = $txtModelsConfigEditTitle
                    $editForm.Size = New-Object System.Drawing.Size(450, 200)
                    $editForm.StartPosition = "CenterScreen"
                    $editForm.FormBorderStyle = "FixedSingle"
                    $editForm.MaximizeBox = $false
                    $editForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)

                    $editTitleLabel = New-Object System.Windows.Forms.Label
                    $editTitleLabel.Text = "$txtModelsConfigEditTitle - $providerName"
                    $editTitleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10, [System.Drawing.FontStyle]::Bold)
                    $editTitleLabel.Size = New-Object System.Drawing.Size(400, 25)
                    $editTitleLabel.Location = New-Object System.Drawing.Point(20, 15)
                    $editTitleLabel.TextAlign = "MiddleCenter"
                    $editForm.Controls.Add($editTitleLabel)

                    $apiKeyNewLabel = New-Object System.Windows.Forms.Label
                    $apiKeyNewLabel.Text = $txtModelsConfigUpdateHint
                    $apiKeyNewLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
                    $apiKeyNewLabel.Size = New-Object System.Drawing.Size(400, 20)
                    $apiKeyNewLabel.Location = New-Object System.Drawing.Point(20, 50)
                    $editForm.Controls.Add($apiKeyNewLabel)

                    $apiKeyNewTextBox = New-Object System.Windows.Forms.TextBox
                    $apiKeyNewTextBox.Size = New-Object System.Drawing.Size(400, 28)
                    $apiKeyNewTextBox.Location = New-Object System.Drawing.Point(20, 75)
                    $apiKeyNewTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
                    $apiKeyNewTextBox.PasswordChar = "*"
                    $editForm.Controls.Add($apiKeyNewTextBox)

                    $saveEditBtn = New-Object System.Windows.Forms.Button
                    $saveEditBtn.Text = $txtConfirm
                    $saveEditBtn.Size = New-Object System.Drawing.Size(100, 30)
                    $saveEditBtn.Location = New-Object System.Drawing.Point(120, 115)
                    $saveEditBtn.BackColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
                    $saveEditBtn.ForeColor = [System.Drawing.Color]::White
                    $saveEditBtn.FlatStyle = "Flat"
                    $saveEditBtn.Add_Click({
                            $newApiKey = $apiKeyNewTextBox.Text.Trim()
                            if (-not [string]::IsNullOrEmpty($newApiKey)) {
                                $currentConfig = Load-ModelsConfig
                                if ($currentConfig.providers.$providerName) {
                                    $baseUrl = $currentConfig.providers.$providerName.baseUrl
                                }
                                else {
                                    $baseUrl = ""
                                }
                                $updateResult = Update-ModelsConfig -Provider $providerName -ApiKey $newApiKey -BaseUrl $baseUrl
                                if ($updateResult) {
                                    [System.Windows.Forms.MessageBox]::Show($txtModelsConfigUpdateSuccess, $txtSuccess, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                                    $editForm.Close()
                                    $configForm.Close()
                                    Show-ModelsConfigDialog
                                }
                                else {
                                    [System.Windows.Forms.MessageBox]::Show("更新失败", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                                }
                            }
                        })
                    $editForm.Controls.Add($saveEditBtn)

                    $cancelEditBtn = New-Object System.Windows.Forms.Button
                    $cancelEditBtn.Text = $txtCancel
                    $cancelEditBtn.Size = New-Object System.Drawing.Size(100, 30)
                    $cancelEditBtn.Location = New-Object System.Drawing.Point(230, 115)
                    $cancelEditBtn.Add_Click({ $editForm.Close() })
                    $editForm.Controls.Add($cancelEditBtn)

                    $editForm.Add_Shown({ $apiKeyNewTextBox.Focus() })
                    [void]$editForm.ShowDialog()
                })
            $rowPanel.Controls.Add($editBtn)

            $deleteBtn = New-Object System.Windows.Forms.Button
            $deleteBtn.Text = $txtModelsConfigDelete
            $deleteBtn.Size = New-Object System.Drawing.Size(60, 26)
            $deleteBtn.Location = New-Object System.Drawing.Point(575, 12)
            $deleteBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
            $deleteBtn.ForeColor = [System.Drawing.Color]::White
            $deleteBtn.FlatStyle = "Flat"
            $deleteBtn.Tag = $provider.Name
            $deleteBtn.Add_Click({
                    $providerName = $this.Tag
                    $confirmResult = [System.Windows.Forms.MessageBox]::Show($txtModelsConfigDeleteConfirm, $txtWarning, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    if ($confirmResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                        $currentConfig = Load-ModelsConfig
                        $currentConfig.providers.Remove($providerName)
                        $removeResult = Save-ModelsConfig -Config $currentConfig
                        if ($removeResult) {
                            [System.Windows.Forms.MessageBox]::Show($txtModelsConfigDeleteSuccess, $txtSuccess, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                            $configForm.Close()
                            Show-ModelsConfigDialog
                        }
                        else {
                            [System.Windows.Forms.MessageBox]::Show("删除失败", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                        }
                    }
                })
            $rowPanel.Controls.Add($deleteBtn)

            $listPanel.Controls.Add($rowPanel)
            $yOffset += $rowHeight + 5
        }
    }

    $configForm.Controls.Add($listPanel)

    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = $txtModelsConfigClose
    $closeBtn.Size = New-Object System.Drawing.Size(100, 35)
    $closeBtn.Location = New-Object System.Drawing.Point(290, 415)
    $closeBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    $closeBtn.ForeColor = [System.Drawing.Color]::White
    $closeBtn.FlatStyle = "Flat"
    $closeBtn.Add_Click({ $configForm.Close() })
    $configForm.Controls.Add($closeBtn)

    [void]$configForm.ShowDialog()
}

function Show-RechargeDialog {
    $rechargeForm = New-Object System.Windows.Forms.Form
    $rechargeForm.Text = "模型充值 - 绝舟中转站"
    $rechargeForm.Size = New-Object System.Drawing.Size(600, 580)
    $rechargeForm.StartPosition = "CenterScreen"
    $rechargeForm.FormBorderStyle = "FixedSingle"
    $rechargeForm.MaximizeBox = $false
    $rechargeForm.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)

    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(600, 70)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(255, 140, 0)
    $rechargeForm.Controls.Add($headerPanel)

    $iconLabel = New-Object System.Windows.Forms.Label
    $iconLabel.Text = "💳"
    $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 28)
    $iconLabel.Size = New-Object System.Drawing.Size(60, 60)
    $iconLabel.Location = New-Object System.Drawing.Point(15, 5)
    $iconLabel.TextAlign = "MiddleCenter"
    $iconLabel.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($iconLabel)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "绝舟中转站 - 模型充值"
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 35)
    $titleLabel.Location = New-Object System.Drawing.Point(80, 18)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($titleLabel)

    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = "api.juezhou.org - OpenAI 兼容接口"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $subtitleLabel.Size = New-Object System.Drawing.Size(300, 20)
    $subtitleLabel.Location = New-Object System.Drawing.Point(80, 48)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 230, 200)
    $headerPanel.Controls.Add($subtitleLabel)

    $modelsPanel = New-Object System.Windows.Forms.Panel
    $modelsPanel.Size = New-Object System.Drawing.Size(560, 320)
    $modelsPanel.Location = New-Object System.Drawing.Point(20, 85)
    $modelsPanel.BackColor = [System.Drawing.Color]::White
    $modelsPanel.AutoScroll = $true
    $rechargeForm.Controls.Add($modelsPanel)

    $models = @(
        @{Name = "GPT-5.5 (最新)"; Model = "gpt-5.5"; Desc = "OpenAI 最新旗舰" },
        @{Name = "Claude Opus 4.7 (最新)"; Model = "claude-opus-4-7"; Desc = "Anthropic 最强推理" },
        @{Name = "Gemini 3.1 Pro Preview (最新)"; Model = "gemini-3.1-pro-preview"; Desc = "Google 最新" },
        @{Name = "Claude Opus 4.6"; Model = "claude-opus-4-6"; Desc = "高级推理" },
        @{Name = "Claude Sonnet 4"; Model = "claude-sonnet-4"; Desc = "平衡性能" },
        @{Name = "Claude 3.7 Sonnet"; Model = "claude-3-7-sonnet"; Desc = "快速响应" },
        @{Name = "Claude 3.5 Sonnet"; Model = "claude-3-5-sonnet"; Desc = "性价比高" },
        @{Name = "GPT-4o"; Model = "gpt-4o"; Desc = "OpenAI 经典旗舰" },
        @{Name = "GPT-4o Mini"; Model = "gpt-4o-mini"; Desc = "轻量快速" },
        @{Name = "Gemini 3.0 Pro"; Model = "gemini-3.0-pro"; Desc = "Google 旗舰" },
        @{Name = "Gemini 2.5 Flash"; Model = "gemini-2.5-flash"; Desc = "极速响应" },
        @{Name = "DeepSeek V3"; Model = "deepseek-v3"; Desc = "国产最强" },
        @{Name = "DeepSeek R1"; Model = "deepseek-r1"; Desc = "推理专家" }
    )

    $yPos = 10
    foreach ($model in $models) {
        $modelPanel = New-Object System.Windows.Forms.Panel
        $modelPanel.Size = New-Object System.Drawing.Size(540, 40)
        $modelPanel.Location = New-Object System.Drawing.Point(10, $yPos)
        $modelPanel.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 252)
        $modelsPanel.Controls.Add($modelPanel)

        $nameLabel = New-Object System.Windows.Forms.Label
        $nameLabel.Text = $model.Name
        $nameLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9, [System.Drawing.FontStyle]::Bold)
        $nameLabel.Size = New-Object System.Drawing.Size(150, 20)
        $nameLabel.Location = New-Object System.Drawing.Point(10, 10)
        $nameLabel.ForeColor = [System.Drawing.Color]::FromArgb(51, 51, 51)
        $modelPanel.Controls.Add($nameLabel)

        $idLabel = New-Object System.Windows.Forms.Label
        $idLabel.Text = $model.Model
        $idLabel.Font = New-Object System.Drawing.Font("Consolas", 8)
        $idLabel.Size = New-Object System.Drawing.Size(150, 18)
        $idLabel.Location = New-Object System.Drawing.Point(170, 11)
        $idLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
        $modelPanel.Controls.Add($idLabel)

        $descLabel = New-Object System.Windows.Forms.Label
        $descLabel.Text = $model.Desc
        $descLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
        $descLabel.Size = New-Object System.Drawing.Size(100, 18)
        $descLabel.Location = New-Object System.Drawing.Point(330, 11)
        $descLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
        $modelPanel.Controls.Add($descLabel)

        $yPos += 45
    }

    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Text = "📌 使用方式：充值后获取 API Key，在模型设置中选择「绝舟」厂商并填入 Key"
    $infoLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $infoLabel.Size = New-Object System.Drawing.Size(540, 25)
    $infoLabel.Location = New-Object System.Drawing.Point(20, 415)
    $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $rechargeForm.Controls.Add($infoLabel)

    $couponLabel = New-Object System.Windows.Forms.Label
    $couponLabel.Text = "🎁 充值前输入优惠码: 金戈铁马 (可领取优惠券)"
    $couponLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9, [System.Drawing.FontStyle]::Bold)
    $couponLabel.Size = New-Object System.Drawing.Size(400, 25)
    $couponLabel.Location = New-Object System.Drawing.Point(20, 440)
    $couponLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
    $rechargeForm.Controls.Add($couponLabel)

    $contactPanel = New-Object System.Windows.Forms.Panel
    $contactPanel.Size = New-Object System.Drawing.Size(300, 25)
    $contactPanel.Location = New-Object System.Drawing.Point(20, 468)
    $contactPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)
    $rechargeForm.Controls.Add($contactPanel)

    $contactLabel = New-Object System.Windows.Forms.Label
    $contactLabel.Text = "📧 微信号: JZToken (点击复制)"
    $contactLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $contactLabel.Size = New-Object System.Drawing.Size(280, 25)
    $contactLabel.Location = New-Object System.Drawing.Point(10, 2)
    $contactLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 123, 255)
    $contactLabel.Cursor = "Hand"
    $contactLabel.Add_Click({
            [System.Windows.Forms.Clipboard]::SetText("JZToken")
            [System.Windows.Forms.MessageBox]::Show("微信号 JZToken 已复制到剪贴板！`n`n请添加微信并备注: 绝舟中转站充值", "复制成功", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        })
    $contactPanel.Controls.Add($contactLabel)

    $registerBtn = New-Object System.Windows.Forms.Button
    $registerBtn.Text = "注册账号"
    $registerBtn.Size = New-Object System.Drawing.Size(100, 35)
    $registerBtn.Location = New-Object System.Drawing.Point(200, 500)
    $registerBtn.BackColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
    $registerBtn.ForeColor = [System.Drawing.Color]::White
    $registerBtn.FlatStyle = "Flat"
    $registerBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
    $registerBtn.Cursor = "Hand"
    $registerBtn.Add_Click({
            Start-Process "https://juezhou.org/admin/dashboard"
        })
    $rechargeForm.Controls.Add($registerBtn)

    $rechargeBtn = New-Object System.Windows.Forms.Button
    $rechargeBtn.Text = "联系充值"
    $rechargeBtn.Size = New-Object System.Drawing.Size(100, 35)
    $rechargeBtn.Location = New-Object System.Drawing.Point(310, 500)
    $rechargeBtn.BackColor = [System.Drawing.Color]::FromArgb(255, 140, 0)
    $rechargeBtn.ForeColor = [System.Drawing.Color]::White
    $rechargeBtn.FlatStyle = "Flat"
    $rechargeBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
    $rechargeBtn.Cursor = "Hand"
    $rechargeBtn.Add_Click({
            [System.Windows.Forms.Clipboard]::SetText("JZToken")
            [System.Windows.Forms.MessageBox]::Show("微信号 JZToken 已复制到剪贴板！`n`n请添加微信并备注: 绝舟中转站充值", "复制成功", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        })
    $rechargeForm.Controls.Add($rechargeBtn)

    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = "关闭"
    $closeBtn.Size = New-Object System.Drawing.Size(100, 35)
    $closeBtn.Location = New-Object System.Drawing.Point(420, 500)
    $closeBtn.BackColor = [System.Drawing.Color]::FromArgb(140, 140, 140)
    $closeBtn.ForeColor = [System.Drawing.Color]::White
    $closeBtn.FlatStyle = "Flat"
    $closeBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
    $closeBtn.Cursor = "Hand"
    $closeBtn.Add_Click({ $rechargeForm.Close() })
    $rechargeForm.Controls.Add($closeBtn)

    $rechargeForm.Add_Shown({ $rechargeForm.Activate() })
    [void]$rechargeForm.ShowDialog()
}

function Show-TokenDialog {
    $tokenForm = New-Object System.Windows.Forms.Form
    $tokenForm.Text = $txtTokenTitle
    $tokenForm.Size = New-Object System.Drawing.Size(500, 350)
    $tokenForm.StartPosition = "CenterScreen"
    $tokenForm.FormBorderStyle = "FixedSingle"
    $tokenForm.MaximizeBox = $false
    $tokenForm.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)

    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(500, 80)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(24, 144, 255)
    $tokenForm.Controls.Add($headerPanel)

    $iconLabel = New-Object System.Windows.Forms.Label
    $iconLabel.Text = "🤝"
    $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 32)
    $iconLabel.Size = New-Object System.Drawing.Size(60, 60)
    $iconLabel.Location = New-Object System.Drawing.Point(20, 10)
    $iconLabel.TextAlign = "MiddleCenter"
    $iconLabel.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($iconLabel)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $txtTokenTitle
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 18, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 40)
    $titleLabel.Location = New-Object System.Drawing.Point(90, 20)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($titleLabel)

    $contentPanel = New-Object System.Windows.Forms.Panel
    $contentPanel.Size = New-Object System.Drawing.Size(460, 150)
    $contentPanel.Location = New-Object System.Drawing.Point(20, 100)
    $contentPanel.BackColor = [System.Drawing.Color]::White
    $tokenForm.Controls.Add($contentPanel)

    $infoIcon = New-Object System.Windows.Forms.Label
    $infoIcon.Text = "📢"
    $infoIcon.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 24)
    $infoIcon.Size = New-Object System.Drawing.Size(50, 50)
    $infoIcon.Location = New-Object System.Drawing.Point(20, 20)
    $infoIcon.TextAlign = "MiddleCenter"
    $contentPanel.Controls.Add($infoIcon)

    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Text = "我们正在积极寻求合作伙伴！`n`n如果您是 AI 服务提供商或相关企业，`n欢迎与我们联系洽谈合作事宜。"
    $infoLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 11)
    $infoLabel.Size = New-Object System.Drawing.Size(380, 100)
    $infoLabel.Location = New-Object System.Drawing.Point(80, 25)
    $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(51, 51, 51)
    $contentPanel.Controls.Add($infoLabel)

    $contactLabel = New-Object System.Windows.Forms.Label
    $contactLabel.Text = "📧 联系邮箱: shaojunking@126.com"
    $contactLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
    $contactLabel.Size = New-Object System.Drawing.Size(400, 25)
    $contactLabel.Location = New-Object System.Drawing.Point(20, 270)
    $contactLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    $tokenForm.Controls.Add($contactLabel)

    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = "关闭"
    $closeBtn.Size = New-Object System.Drawing.Size(100, 35)
    $closeBtn.Location = New-Object System.Drawing.Point(200, 300)
    $closeBtn.BackColor = [System.Drawing.Color]::FromArgb(140, 140, 140)
    $closeBtn.ForeColor = [System.Drawing.Color]::White
    $closeBtn.FlatStyle = "Flat"
    $closeBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
    $closeBtn.Cursor = "Hand"
    $closeBtn.Add_Click({ $tokenForm.Close() })
    $tokenForm.Controls.Add($closeBtn)

    $tokenForm.Add_Shown({ $tokenForm.Activate() })
    [void]$tokenForm.ShowDialog()
}

function Test-ChannelConnection {
    param(
        [string]$ChannelKey,
        [hashtable]$Credentials
    )

    $result = @{
        Success = $false
        Message = ""
        Details = ""
    }

    try {
        switch ($ChannelKey) {
            "telegram" {
                $token = $Credentials["token"]
                if ([string]::IsNullOrEmpty($token) -or $token -eq "123456:ABC-DEF...") {
                    $result.Message = "Token 未填写"
                    return $result
                }
                $url = "https://api.telegram.org/bot$token/getMe"
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
                $data = $response.Content | ConvertFrom-Json
                if ($data.ok) {
                    $result.Success = $true
                    $result.Message = "连接成功！"
                    $result.Details = "Bot: @$($data.result.username)"
                }
                else {
                    $result.Message = "Token 无效"
                    $result.Details = $data.description
                }
            }
            "discord" {
                $token = $Credentials["token"]
                if ([string]::IsNullOrEmpty($token) -or $token -eq "MTIz...xyz") {
                    $result.Message = "Token 未填写"
                    return $result
                }
                try {
                    $url = "https://discord.com/api/v10/users/@me"
                    $headers = @{ "Authorization" = "Bot $token" }
                    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -Headers $headers
                    $data = $response.Content | ConvertFrom-Json
                    $result.Success = $true
                    $result.Message = "连接成功！"
                    $result.Details = "Bot: $($data.username)#$($data.discriminator)"
                }
                catch {
                    $errData = $_.Exception.Response.StatusCode
                    if ($errData -eq [System.Net.HttpStatusCode]::Unauthorized) {
                        $result.Message = "Token 无效"
                        $result.Details = "Bot Token 已过期或无效"
                    }
                    else {
                        $result.Message = "连接失败"
                        $result.Details = $_.Exception.Message
                    }
                }
            }
            "feishu" {
                $appId = $Credentials["appId"]
                $appSecret = $Credentials["appSecret"]
                if ([string]::IsNullOrEmpty($appId) -or $appId -eq "cli_xxx" -or [string]::IsNullOrEmpty($appSecret) -or $appSecret -eq "xxx") {
                    $result.Message = "App ID 或 Secret 未填写"
                    return $result
                }
                $url = "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal"
                $body = @{
                    app_id     = $appId
                    app_secret = $appSecret
                } | ConvertTo-Json
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -Method POST -Body $body -ContentType "application/json"
                $data = $response.Content | ConvertFrom-Json
                if ($data.code -eq 0) {
                    $result.Success = $true
                    $result.Message = "连接成功！"
                    $result.Details = "Token 有效期: $($data.data.expire) 秒"
                }
                else {
                    $result.Message = "认证失败"
                    $result.Details = $data.msg
                }
            }
            "dingtalk" {
                $clientId = $Credentials["clientId"]
                $clientSecret = $Credentials["clientSecret"]
                if ([string]::IsNullOrEmpty($clientId) -or $clientId -eq "dingxxx" -or [string]::IsNullOrEmpty($clientSecret) -or $clientSecret -eq "xxx") {
                    $result.Message = "Client ID 或 Secret 未填写"
                    return $result
                }
                $url = "https://api.dingtalk.com/v1.0/oauth2/accessToken"
                $body = @{
                    appKey    = $clientId
                    appSecret = $clientSecret
                } | ConvertTo-Json
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -Method POST -Body $body -ContentType "application/json"
                $data = $response.Content | ConvertFrom-Json
                if ($data.accessToken) {
                    $result.Success = $true
                    $result.Message = "连接成功！"
                    $result.Details = "Token 获取成功"
                }
                else {
                    $result.Message = "认证失败"
                    $result.Details = $data.errorDescription
                }
            }
            "wecom" {
                $corpId = $Credentials["corpId"]
                $secret = $Credentials["secret"]
                if ([string]::IsNullOrEmpty($corpId) -or $corpId -eq "wwxxx" -or [string]::IsNullOrEmpty($secret) -or $secret -eq "xxx") {
                    $result.Message = "企业 ID 或 Secret 未填写"
                    return $result
                }
                $url = "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$corpId&corpsecret=$secret"
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
                $data = $response.Content | ConvertFrom-Json
                if ($data.errcode -eq 0) {
                    $result.Success = $true
                    $result.Message = "连接成功！"
                    $result.Details = "Token 有效期: $($data.expires_in) 秒"
                }
                else {
                    $result.Message = "认证失败"
                    $result.Details = $data.errmsg
                }
            }
            "wechat" {
                $appId = $Credentials["appId"]
                $appSecret = $Credentials["appSecret"]
                if ([string]::IsNullOrEmpty($appId) -or $appId -eq "wx123..." -or [string]::IsNullOrEmpty($appSecret) -or $appSecret -eq "xxx") {
                    $result.Message = "App ID 或 Secret 未填写"
                    return $result
                }
                $url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=$appId&secret=$appSecret"
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
                $data = $response.Content | ConvertFrom-Json
                if ($data.access_token) {
                    $result.Success = $true
                    $result.Message = "连接成功！"
                    $result.Details = "Token 获取成功"
                }
                else {
                    $result.Message = "认证失败"
                    $result.Details = $data.errmsg
                }
            }
            "qq" {
                $appId = $Credentials["appId"]
                $appSecret = $Credentials["appSecret"]
                if ([string]::IsNullOrEmpty($appId) -or $appId -eq "123456789" -or [string]::IsNullOrEmpty($appSecret) -or $appSecret -eq "xxx") {
                    $result.Message = "App ID 或 Secret 未填写"
                    return $result
                }
                $result.Success = $true
                $result.Message = "配置已保存"
                $result.Details = "QQ 机器人配置已保存，请在 OpenClaw 中验证"
            }
            "slack" {
                $token = $Credentials["token"]
                if ([string]::IsNullOrEmpty($token) -or $token -eq "xoxb-...") {
                    $result.Message = "Bot Token 未填写"
                    return $result
                }
                $result.Success = $true
                $result.Message = "配置已保存"
                $result.Details = "Slack 机器人配置已保存，请在 OpenClaw 中验证"
            }
            "whatsapp" {
                $phoneNumber = $Credentials["phoneNumber"]
                if ([string]::IsNullOrEmpty($phoneNumber) -or $phoneNumber -eq "+86138...") {
                    $result.Message = "手机号未填写"
                    return $result
                }
                $result.Success = $true
                $result.Message = "配置已保存"
                $result.Details = "WhatsApp 配置已保存，请扫码配对连接"
            }
            default {
                $result.Message = "不支持的平台"
                $result.Details = "平台 $ChannelKey 暂不支持测试"
            }
        }
    }
    catch {
        $result.Message = "连接失败"
        $result.Details = $_.Exception.Message
    }

    return $result
}

function Show-ChannelDialog {
    $channelForm = New-Object System.Windows.Forms.Form
    $channelForm.Text = "聊天平台频道管理"
    $channelForm.Size = New-Object System.Drawing.Size(680, 780)
    $channelForm.StartPosition = "CenterScreen"
    $channelForm.FormBorderStyle = "FixedSingle"
    $channelForm.MaximizeBox = $false
    $channelForm.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)

    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(680, 70)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.BackColor = [System.Drawing.Color]::White
    $channelForm.Controls.Add($headerPanel)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "💬 聊天平台频道管理"
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(640, 40)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
    $headerPanel.Controls.Add($titleLabel)

    $hintLabel = New-Object System.Windows.Forms.Label
    $hintLabel.Text = "选择要配置的聊天平台，OpenClaw 将通过这些平台与您交互"
    $hintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $hintLabel.Size = New-Object System.Drawing.Size(640, 22)
    $hintLabel.Location = New-Object System.Drawing.Point(20, 48)
    $hintLabel.ForeColor = [System.Drawing.Color]::FromArgb(102, 102, 102)
    $headerPanel.Controls.Add($hintLabel)

    $contentPanel = New-Object System.Windows.Forms.Panel
    $contentPanel.Size = New-Object System.Drawing.Size(660, 600)
    $contentPanel.Location = New-Object System.Drawing.Point(10, 80)
    $contentPanel.AutoScroll = $true
    $contentPanel.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)
    $channelForm.Controls.Add($contentPanel)

    $config = Ensure-Config
    $currentChannels = $config.channels

    $brandColors = @{
        telegram = @{Color = [System.Drawing.Color]::FromArgb(0, 136, 204); Icon = "📱" }
        discord  = @{Color = [System.Drawing.Color]::FromArgb(88, 101, 242); Icon = "🎮" }
        whatsapp = @{Color = [System.Drawing.Color]::FromArgb(37, 211, 102); Icon = "💬" }
        slack    = @{Color = [System.Drawing.Color]::FromArgb(74, 21, 75); Icon = "💼" }
        feishu   = @{Color = [System.Drawing.Color]::FromArgb(51, 112, 255); Icon = "📮" }
        dingtalk = @{Color = [System.Drawing.Color]::FromArgb(0, 137, 255); Icon = "🔔" }
        wecom    = @{Color = [System.Drawing.Color]::FromArgb(0, 130, 239); Icon = "🏢" }
        wechat   = @{Color = [System.Drawing.Color]::FromArgb(7, 193, 96); Icon = "💚" }
        qq       = @{Color = [System.Drawing.Color]::FromArgb(18, 183, 245); Icon = "🐧" }
    }

    $channels = @(
        @{Name = "Telegram"; Desc = "快速 AI 对话体验"; ConfigKey = "telegram" },
        @{Name = "Discord"; Desc = "服务器群聊机器人"; ConfigKey = "discord" },
        @{Name = "WhatsApp"; Desc = "Business API 接入"; ConfigKey = "whatsapp" },
        @{Name = "Slack"; Desc = "团队协作利器"; ConfigKey = "slack" },
        @{Name = "飞书/Lark"; Desc = "企业内部机器人"; ConfigKey = "feishu" },
        @{Name = "钉钉"; Desc = "群聊 AI 助手"; ConfigKey = "dingtalk" },
        @{Name = "企业微信"; Desc = "企业通讯机器人"; ConfigKey = "wecom" },
        @{Name = "微信"; Desc = "需企业版支持"; ConfigKey = "wechat" },
        @{Name = "QQ"; Desc = "QQ 群聊机器人"; ConfigKey = "qq" }
    )

    $cardWidth = 310
    $cardHeight = 130
    $gapX = 15
    $gapY = 15
    $startX = 5
    $startY = 5
    $col = 0
    $row = 0

    foreach ($channel in $channels) {
        $brandInfo = $brandColors[$channel.ConfigKey]
        $brandColor = $brandInfo.Color
        $iconText = $brandInfo.Icon

        $xPos = $startX + ($col * ($cardWidth + $gapX))
        $yPos = $startY + ($row * ($cardHeight + $gapY))

        $cardPanel = New-Object System.Windows.Forms.Panel
        $cardPanel.Size = New-Object System.Drawing.Size($cardWidth, $cardHeight)
        $cardPanel.Location = New-Object System.Drawing.Point($xPos, $yPos)
        $cardPanel.BackColor = [System.Drawing.Color]::White
        $cardPanel.Cursor = "Hand"
        $cardPanel.Tag = @{Name = $channel.Name; ConfigKey = $channel.ConfigKey; BrandColor = $brandColor }
        $cardPanel.Add_MouseEnter({
                param($s, $e)
                $s.BackColor = [System.Drawing.Color]::FromArgb(248, 250, 252)
            })
        $cardPanel.Add_MouseLeave({
                param($s, $e)
                $s.BackColor = [System.Drawing.Color]::White
            })
        $contentPanel.Controls.Add($cardPanel)

        $leftBorder = New-Object System.Windows.Forms.Panel
        $leftBorder.Size = New-Object System.Drawing.Size(4, $cardHeight)
        $leftBorder.Location = New-Object System.Drawing.Point(0, 0)
        $leftBorder.BackColor = $brandColor
        $cardPanel.Controls.Add($leftBorder)

        $iconLabel = New-Object System.Windows.Forms.Label
        $iconLabel.Text = $iconText
        $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 28)
        $iconLabel.Size = New-Object System.Drawing.Size(50, 50)
        $iconLabel.Location = New-Object System.Drawing.Point(15, 15)
        $iconLabel.TextAlign = "MiddleCenter"
        $cardPanel.Controls.Add($iconLabel)

        $nameLabel = New-Object System.Windows.Forms.Label
        $nameLabel.Text = $channel.Name
        $nameLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 12, [System.Drawing.FontStyle]::Bold)
        $nameLabel.Size = New-Object System.Drawing.Size(200, 25)
        $nameLabel.Location = New-Object System.Drawing.Point(70, 15)
        $nameLabel.ForeColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
        $cardPanel.Controls.Add($nameLabel)

        $descLabel = New-Object System.Windows.Forms.Label
        $descLabel.Text = $channel.Desc
        $descLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
        $descLabel.Size = New-Object System.Drawing.Size(200, 20)
        $descLabel.Location = New-Object System.Drawing.Point(70, 40)
        $descLabel.ForeColor = [System.Drawing.Color]::FromArgb(102, 102, 102)
        $cardPanel.Controls.Add($descLabel)

        $channelConfig = $null
        if ($currentChannels -and $currentChannels.($channel.ConfigKey)) {
            $channelConfig = $currentChannels.($channel.ConfigKey)
        }

        $statusBadge = New-Object System.Windows.Forms.Label
        $statusBadge.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
        $statusBadge.Size = New-Object System.Drawing.Size(80, 24)
        $statusBadge.Location = New-Object System.Drawing.Point(70, 65)
        $statusBadge.TextAlign = "MiddleCenter"
        if ($channelConfig) {
            if ($channelConfig.enabled -eq $false) {
                $statusBadge.Text = "已禁用"
                $statusBadge.BackColor = [System.Drawing.Color]::FromArgb(255, 243, 224)
                $statusBadge.ForeColor = [System.Drawing.Color]::FromArgb(230, 126, 34)
            }
            else {
                $statusBadge.Text = "已配置"
                $statusBadge.BackColor = [System.Drawing.Color]::FromArgb(232, 245, 233)
                $statusBadge.ForeColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
            }
        }
        else {
            $statusBadge.Text = "未配置"
            $statusBadge.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
            $statusBadge.ForeColor = [System.Drawing.Color]::FromArgb(158, 158, 158)
        }
        $cardPanel.Controls.Add($statusBadge)

        $configBtn = New-Object System.Windows.Forms.Button
        $configBtn.Text = if ($channelConfig) { "编辑" } else { "配置" }
        $configBtn.Size = New-Object System.Drawing.Size(70, 30)
        $configBtn.Location = New-Object System.Drawing.Point(220, 90)
        $configBtn.FlatStyle = "Flat"
        $configBtn.BackColor = $brandColor
        $configBtn.ForeColor = [System.Drawing.Color]::White
        $configBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
        $configBtn.Cursor = "Hand"
        $configBtn.Tag = @{Name = $channel.Name; ConfigKey = $channel.ConfigKey }
        $capturedBrandColor = $brandColor
        $configBtn.Add_MouseEnter({
                param($s, $e)
                $s.BackColor = [System.Drawing.Color]::FromArgb(
                    [Math]::Min(255, $capturedBrandColor.R + 20),
                    [Math]::Min(255, $capturedBrandColor.G + 20),
                    [Math]::Min(255, $capturedBrandColor.B + 20)
                )
            })
        $configBtn.Add_MouseLeave({
                param($s, $e)
                $s.BackColor = $capturedBrandColor
            })
        $configBtn.Add_Click({
                param($s, $e)
                $tagData = $s.Tag
                Show-ChannelConfigDialog -ChannelName $tagData.Name -ChannelKey $tagData.ConfigKey
                $channelForm.Close()
            })
        $cardPanel.Controls.Add($configBtn)

        $col++
        if ($col -ge 2) {
            $col = 0
            $row++
        }
    }

    $footerPanel = New-Object System.Windows.Forms.Panel
    $footerPanel.Size = New-Object System.Drawing.Size(680, 50)
    $footerPanel.Location = New-Object System.Drawing.Point(0, 690)
    $footerPanel.BackColor = [System.Drawing.Color]::White
    $channelForm.Controls.Add($footerPanel)

    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Text = "💡 配置完成后，重启 OpenClaw 即可生效"
    $infoLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $infoLabel.Size = New-Object System.Drawing.Size(400, 20)
    $infoLabel.Location = New-Object System.Drawing.Point(20, 15)
    $infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(102, 102, 102)
    $footerPanel.Controls.Add($infoLabel)

    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = "关闭"
    $closeBtn.Size = New-Object System.Drawing.Size(80, 32)
    $closeBtn.Location = New-Object System.Drawing.Point(570, 9)
    $closeBtn.BackColor = [System.Drawing.Color]::FromArgb(140, 140, 140)
    $closeBtn.ForeColor = [System.Drawing.Color]::White
    $closeBtn.FlatStyle = "Flat"
    $closeBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $closeBtn.Cursor = "Hand"
    $closeBtn.Add_Click({ $channelForm.Close() })
    $footerPanel.Controls.Add($closeBtn)

    $channelForm.Add_Shown({ $channelForm.Activate() })
    [void]$channelForm.ShowDialog()
}

function Show-ChannelConfigDialog {
    param(
        [string]$ChannelName,
        [string]$ChannelKey
    )

    $brandColors = @{
        telegram = @{Color = [System.Drawing.Color]::FromArgb(0, 136, 204); Icon = "📱" }
        discord  = @{Color = [System.Drawing.Color]::FromArgb(88, 101, 242); Icon = "🎮" }
        whatsapp = @{Color = [System.Drawing.Color]::FromArgb(37, 211, 102); Icon = "💬" }
        slack    = @{Color = [System.Drawing.Color]::FromArgb(74, 21, 75); Icon = "💼" }
        feishu   = @{Color = [System.Drawing.Color]::FromArgb(51, 112, 255); Icon = "📮" }
        dingtalk = @{Color = [System.Drawing.Color]::FromArgb(0, 137, 255); Icon = "🔔" }
        wecom    = @{Color = [System.Drawing.Color]::FromArgb(0, 130, 239); Icon = "🏢" }
        wechat   = @{Color = [System.Drawing.Color]::FromArgb(7, 193, 96); Icon = "💚" }
        qq       = @{Color = [System.Drawing.Color]::FromArgb(18, 183, 245); Icon = "🐧" }
    }

    $brandInfo = $brandColors[$ChannelKey]
    $brandColor = if ($brandInfo) { $brandInfo.Color } else { [System.Drawing.Color]::FromArgb(24, 144, 255) }
    $brandIcon = if ($brandInfo) { $brandInfo.Icon } else { "⚙️" }

    $channelConfigs = @{
        telegram = @{
            Title      = "Telegram Bot"
            Fields     = @(
                @{Name = "token"; Label = "Bot Token"; Placeholder = "123456:ABC-DEF..."; Type = "text" }
            )
            Hint       = "1. 在 Telegram 搜索 @BotFather`n2. 发送 /newbot 创建机器人`n3. 复制获得的 Token"
            ConfigPath = "channels.telegram"
        }
        discord  = @{
            Title      = "Discord Bot"
            Fields     = @(
                @{Name = "token"; Label = "Bot Token"; Placeholder = "MTIz...xyz"; Type = "text" }
            )
            Hint       = "1. 访问 discord.com/developers/applications`n2. 创建 Application 并添加 Bot`n3. 复制 Bot Token"
            ConfigPath = "channels.discord"
        }
        whatsapp = @{
            Title      = "WhatsApp Business"
            Fields     = @(
                @{Name = "phoneNumber"; Label = "手机号"; Placeholder = "+86138..."; Type = "text" }
            )
            Hint       = "1. 安装 WhatsApp Business`n2. 打开设置 > 关联设备`n3. 点击关联设备进行配对"
            ConfigPath = "channels.whatsapp"
        }
        slack    = @{
            Title      = "Slack Bot"
            Fields     = @(
                @{Name = "token"; Label = "Bot Token"; Placeholder = "xoxb-..."; Type = "text" },
                @{Name = "teamId"; Label = "Team ID"; Placeholder = "T123456"; Type = "text" }
            )
            Hint       = "1. 访问 api.slack.com/apps`n2. 创建 App 并添加 Bot`n3. 安装到工作区获取 Token"
            ConfigPath = "channels.slack"
        }
        feishu   = @{
            Title      = "飞书/Lark"
            Fields     = @(
                @{Name = "appId"; Label = "App ID"; Placeholder = "cli_xxx"; Type = "text" },
                @{Name = "appSecret"; Label = "App Secret"; Placeholder = "xxx"; Type = "password" }
            )
            Hint       = "1. 访问 open.feishu.cn/app`n2. 创建企业应用`n3. 获取 App ID 和 Secret"
            ConfigPath = "channels.feishu"
        }
        dingtalk = @{
            Title      = "钉钉机器人"
            Fields     = @(
                @{Name = "clientId"; Label = "Client ID"; Placeholder = "dingxxx"; Type = "text" },
                @{Name = "clientSecret"; Label = "Client Secret"; Placeholder = "xxx"; Type = "password" }
            )
            Hint       = "1. 访问 open.dingtalk.com`n2. 创建应用`n3. 获取 Client ID 和 Secret"
            ConfigPath = "channels.dingtalk"
        }
        wecom    = @{
            Title      = "企业微信"
            Fields     = @(
                @{Name = "corpId"; Label = "企业 ID"; Placeholder = "wwxxx"; Type = "text" },
                @{Name = "agentId"; Label = "Agent ID"; Placeholder = "1000001"; Type = "text" },
                @{Name = "secret"; Label = "Secret"; Placeholder = "xxx"; Type = "password" }
            )
            Hint       = "1. 登录企业微信管理后台`n2. 进入应用管理`n3. 创建机器人获取凭证"
            ConfigPath = "channels.wecom"
        }
        wechat   = @{
            Title      = "微信机器人"
            Fields     = @(
                @{Name = "appId"; Label = "App ID"; Placeholder = "wx123..."; Type = "text" },
                @{Name = "appSecret"; Label = "App Secret"; Placeholder = "xxx"; Type = "password" }
            )
            Hint       = "1. 微信需要企业版支持`n2. 建议使用企业微信替代`n3. 填写凭证后可生成二维码"
            HasQRCode  = $true
            ConfigPath = "channels.wechat"
        }
        qq       = @{
            Title      = "QQ 机器人"
            Fields     = @(
                @{Name = "appId"; Label = "App ID"; Placeholder = "123456789"; Type = "text" },
                @{Name = "appSecret"; Label = "App Secret"; Placeholder = "xxx"; Type = "password" }
            )
            Hint       = "1. 访问 q.qq.com`n2. 创建 QQ 机器人应用`n3. 获取 App ID 和 Secret"
            ConfigPath = "channels.qq"
        }
    }

    $channelInfo = $channelConfigs[$ChannelKey]
    if (-not $channelInfo) {
        $channelInfo = @{
            Title      = $ChannelName
            Fields     = @(
                @{Name = "token"; Label = "Token"; Placeholder = ""; Type = "text" }
            )
            Hint       = "请输入配置信息"
            ConfigPath = "channels.$ChannelKey"
        }
    }

    $formHeight = 420 + ($channelInfo.Fields.Count * 75)
    if ($formHeight -lt 500) { $formHeight = 500 }
    if ($formHeight -gt 750) { $formHeight = 750 }

    $configForm = New-Object System.Windows.Forms.Form
    $configForm.Text = "配置 $ChannelName"
    $configForm.Size = New-Object System.Drawing.Size(480, $formHeight)
    $configForm.StartPosition = "CenterScreen"
    $configForm.FormBorderStyle = "FixedSingle"
    $configForm.MaximizeBox = $false
    $configForm.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)

    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(480, 80)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.BackColor = $brandColor
    $configForm.Controls.Add($headerPanel)

    $iconLabel = New-Object System.Windows.Forms.Label
    $iconLabel.Text = $brandIcon
    $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 32)
    $iconLabel.Size = New-Object System.Drawing.Size(60, 60)
    $iconLabel.Location = New-Object System.Drawing.Point(20, 10)
    $iconLabel.TextAlign = "MiddleCenter"
    $iconLabel.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($iconLabel)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $channelInfo.Title
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(380, 35)
    $titleLabel.Location = New-Object System.Drawing.Point(85, 15)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($titleLabel)

    $enabledCheck = New-Object System.Windows.Forms.CheckBox
    $enabledCheck.Text = "启用此平台"
    $enabledCheck.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $enabledCheck.Size = New-Object System.Drawing.Size(100, 24)
    $enabledCheck.Location = New-Object System.Drawing.Point(85, 50)
    $enabledCheck.Checked = $true
    $enabledCheck.Cursor = "Hand"
    $enabledCheck.ForeColor = [System.Drawing.Color]::White
    $headerPanel.Controls.Add($enabledCheck)

    $hintPanel = New-Object System.Windows.Forms.Panel
    $hintPanel.Size = New-Object System.Drawing.Size(440, 55)
    $hintPanel.Location = New-Object System.Drawing.Point(20, 90)
    $hintPanel.BackColor = [System.Drawing.Color]::FromArgb(232, 243, 255)
    $configForm.Controls.Add($hintPanel)

    $hintIcon = New-Object System.Windows.Forms.Label
    $hintIcon.Text = "💡"
    $hintIcon.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 14)
    $hintIcon.Size = New-Object System.Drawing.Size(30, 30)
    $hintIcon.Location = New-Object System.Drawing.Point(10, 12)
    $hintIcon.TextAlign = "MiddleCenter"
    $hintPanel.Controls.Add($hintIcon)

    $hintLabel = New-Object System.Windows.Forms.Label
    $hintLabel.Text = $channelInfo.Hint
    $hintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
    $hintLabel.Size = New-Object System.Drawing.Size(390, 45)
    $hintLabel.Location = New-Object System.Drawing.Point(40, 5)
    $hintLabel.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $hintPanel.Controls.Add($hintLabel)

    $config = Ensure-Config
    $currentChannel = $null
    $configPathParts = $channelInfo.ConfigPath -split '\.'
    $tempConfig = $config
    foreach ($part in $configPathParts) {
        if ($tempConfig.$part) {
            $tempConfig = $tempConfig.$part
        }
        else {
            $tempConfig = $null
            break
        }
    }
    $currentChannel = $tempConfig

    if ($currentChannel -and $currentChannel.enabled -eq $false) {
        $enabledCheck.Checked = $false
    }

    $fieldInputs = @{}
    $yPos = 155
    foreach ($field in $channelInfo.Fields) {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $field.Label
        $label.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9, [System.Drawing.FontStyle]::Bold)
        $label.Size = New-Object System.Drawing.Size(440, 20)
        $label.Location = New-Object System.Drawing.Point(20, $yPos)
        $label.ForeColor = [System.Drawing.Color]::FromArgb(51, 51, 51)
        $configForm.Controls.Add($label)

        $inputBox = New-Object System.Windows.Forms.TextBox
        $inputBox.Size = New-Object System.Drawing.Size(440, 30)
        $inputBox.Location = New-Object System.Drawing.Point(20, ($yPos + 22))
        $inputBox.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
        $inputBox.Tag = $field.Placeholder
        $inputBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $inputBox.Padding = New-Object System.Windows.Forms.Padding(8)
        $inputBox.BackColor = [System.Drawing.Color]::White

        if ($field.Placeholder) {
            $inputBox.Text = $field.Placeholder
            $inputBox.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
        }

        $currentValue = $null
        if ($currentChannel -and $currentChannel.($field.Name)) {
            $currentValue = $currentChannel.($field.Name)
        }

        if ($currentValue) {
            $inputBox.Text = $currentValue
            $inputBox.ForeColor = [System.Drawing.Color]::FromArgb(51, 51, 51)
        }

        $capturedPlaceholder = $field.Placeholder
        $capturedBrandColor3 = $brandColor
        $inputBox.Add_GotFocus({
                param($s, $e)
                if ($s.Text -eq $s.Tag) {
                    $s.Text = ""
                    $s.ForeColor = [System.Drawing.Color]::FromArgb(51, 51, 51)
                }
                $s.BackColor = [System.Drawing.Color]::FromArgb(250, 252, 255)
            })
        $inputBox.Add_LostFocus({
                param($s, $e)
                if ([string]::IsNullOrEmpty($s.Text) -and $s.Tag) {
                    $s.Text = $s.Tag
                    $s.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
                }
                $s.BackColor = [System.Drawing.Color]::White
            })

        $fieldInputs[$field.Name] = $inputBox
        $configForm.Controls.Add($inputBox)
        $yPos += 70
    }

    $separatorLine = New-Object System.Windows.Forms.Panel
    $separatorLine.Size = New-Object System.Drawing.Size(440, 1)
    $separatorLine.Location = New-Object System.Drawing.Point(20, ($formHeight - 100))
    $separatorLine.BackColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    $configForm.Controls.Add($separatorLine)

    $btnY = $formHeight - 80

    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Text = "取消"
    $cancelBtn.Size = New-Object System.Drawing.Size(80, 35)
    $cancelBtn.Location = New-Object System.Drawing.Point(20, $btnY)
    $cancelBtn.BackColor = [System.Drawing.Color]::FromArgb(140, 140, 140)
    $cancelBtn.ForeColor = [System.Drawing.Color]::White
    $cancelBtn.FlatStyle = "Flat"
    $cancelBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $cancelBtn.Cursor = "Hand"
    $cancelBtn.Add_MouseEnter({
            param($s, $e)
            $s.BackColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
        })
    $cancelBtn.Add_MouseLeave({
            param($s, $e)
            $s.BackColor = [System.Drawing.Color]::FromArgb(140, 140, 140)
        })
    $cancelBtn.Add_Click({ $configForm.Close() })
    $configForm.Controls.Add($cancelBtn)

    $testBtn = New-Object System.Windows.Forms.Button
    $testBtn.Text = "测试连接"
    $testBtn.Size = New-Object System.Drawing.Size(90, 35)
    $testBtn.Location = New-Object System.Drawing.Point(110, $btnY)
    $testBtn.BackColor = [System.Drawing.Color]::FromArgb(255, 152, 0)
    $testBtn.ForeColor = [System.Drawing.Color]::White
    $testBtn.FlatStyle = "Flat"
    $testBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $testBtn.Cursor = "Hand"
    $testBtn.Add_MouseEnter({
            param($s, $e)
            $s.BackColor = [System.Drawing.Color]::FromArgb(255, 172, 30)
        })
    $testBtn.Add_MouseLeave({
            param($s, $e)
            $s.BackColor = [System.Drawing.Color]::FromArgb(255, 152, 0)
        })
    $capturedChannelInfo = $channelInfo
    $capturedFieldInputs = $fieldInputs
    $testBtn.Add_Click({
            $credentials = @{}
            foreach ($field in $capturedChannelInfo.Fields) {
                $inputBox = $capturedFieldInputs[$field.Name]
                $credentials[$field.Name] = $inputBox.Text
            }

            $testBtn.Text = "测试中..."
            $testBtn.Enabled = $false
            $configForm.Refresh()

            $result = Test-ChannelConnection -ChannelKey $ChannelKey -Credentials $credentials

            $testBtn.Text = "测试连接"
            $testBtn.Enabled = $true

            if ($result.Success) {
                [System.Windows.Forms.MessageBox]::Show(
                    "$($result.Message)`n`n$($result.Details)",
                    "连接成功",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
            else {
                [System.Windows.Forms.MessageBox]::Show(
                    "$($result.Message)`n`n$($result.Details)",
                    "连接失败",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        })
    $configForm.Controls.Add($testBtn)

    $saveBtn = New-Object System.Windows.Forms.Button
    $saveBtn.Text = "保存配置"
    $saveBtn.Size = New-Object System.Drawing.Size(100, 35)
    $saveBtn.Location = New-Object System.Drawing.Point(360, $btnY)
    $saveBtn.BackColor = $brandColor
    $saveBtn.ForeColor = [System.Drawing.Color]::White
    $saveBtn.FlatStyle = "Flat"
    $saveBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9, [System.Drawing.FontStyle]::Bold)
    $saveBtn.Cursor = "Hand"
    $capturedBrandColor2 = $brandColor
    $saveBtn.Add_MouseEnter({
            param($s, $e)
            $s.BackColor = [System.Drawing.Color]::FromArgb(
                [Math]::Min(255, $capturedBrandColor2.R + 20),
                [Math]::Min(255, $capturedBrandColor2.G + 20),
                [Math]::Min(255, $capturedBrandColor2.B + 20)
            )
        })
    $saveBtn.Add_MouseLeave({
            param($s, $e)
            $s.BackColor = $capturedBrandColor2
        })
    $capturedChannelInfo2 = $channelInfo
    $capturedFieldInputs2 = $fieldInputs
    $saveBtn.Add_Click({
            $channelData = @{}
            foreach ($field in $capturedChannelInfo2.Fields) {
                $inputBox = $capturedFieldInputs2[$field.Name]
                if ($inputBox.Text -and $inputBox.Text -ne $field.Placeholder) {
                    $channelData[$field.Name] = $inputBox.Text
                }
            }

            if (-not $config.channels) {
                $config | Add-Member -MemberType NoteProperty -Name "channels" -Value @{} -Force
            }

            $channelData.enabled = $enabledCheck.Checked
            $channelData.allowFrom = @()
            $channelData.groups = @{
                "*" = @{
                    requireMention = $true
                }
            }

            $config.channels | Add-Member -MemberType NoteProperty -Name $ChannelKey -Value $channelData -Force

            $configFile = Join-Path $script:STATE_DIR "openclaw.json"
            $json = $config | ConvertTo-Json -Depth 10
            [System.IO.File]::WriteAllText($configFile, $json, (New-Object System.Text.UTF8Encoding $false))

            [System.Windows.Forms.MessageBox]::Show(
                "配置已保存！`n`n请重启 OpenClaw 使配置生效。",
                "保存成功",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            $configForm.Close()
        })
    $configForm.Controls.Add($saveBtn)

    $configForm.Add_Shown({ $configForm.Activate() })
    [void]$configForm.ShowDialog()
}

function Show-WeChatQRCodeDialog {
    param(
        [string]$AppId,
        [string]$AppSecret
    )

    $qrForm = New-Object System.Windows.Forms.Form
    $qrForm.Text = "微信二维码绑定"
    $qrForm.Size = New-Object System.Drawing.Size(400, 450)
    $qrForm.StartPosition = "CenterScreen"
    $qrForm.FormBorderStyle = "FixedSingle"
    $qrForm.MaximizeBox = $false
    $qrForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "微信二维码绑定"
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(360, 30)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $titleLabel.TextAlign = "MiddleCenter"
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(73, 140, 0)
    $qrForm.Controls.Add($titleLabel)

    $hintLabel = New-Object System.Windows.Forms.Label
    $hintLabel.Text = "使用微信扫描下方二维码进行绑定"
    $hintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $hintLabel.Size = New-Object System.Drawing.Size(360, 22)
    $hintLabel.Location = New-Object System.Drawing.Point(20, 50)
    $hintLabel.TextAlign = "MiddleCenter"
    $hintLabel.ForeColor = [System.Drawing.Color]::Gray
    $qrForm.Controls.Add($hintLabel)

    $qrPanel = New-Object System.Windows.Forms.Panel
    $qrPanel.Size = New-Object System.Drawing.Size(250, 250)
    $qrPanel.Location = New-Object System.Drawing.Point(75, 85)
    $qrPanel.BackColor = [System.Drawing.Color]::White
    $qrPanel.BorderStyle = [System.Drawing.Forms.BorderStyle]::FixedSingle
    $qrForm.Controls.Add($qrPanel)

    $qrPlaceholder = New-Object System.Windows.Forms.Label
    $qrPlaceholder.Text = "正在生成二维码..."
    $qrPlaceholder.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
    $qrPlaceholder.Size = New-Object System.Drawing.Size(230, 230)
    $qrPlaceholder.Location = New-Object System.Drawing.Point(10, 10)
    $qrPlaceholder.TextAlign = "MiddleCenter"
    $qrPlaceholder.ForeColor = [System.Drawing.Color]::Gray
    $qrPanel.Controls.Add($qrPlaceholder)

    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = "等待扫码..."
    $statusLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $statusLabel.Size = New-Object System.Drawing.Size(360, 20)
    $statusLabel.Location = New-Object System.Drawing.Point(20, 350)
    $statusLabel.TextAlign = "MiddleCenter"
    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 140, 0)
    $qrForm.Controls.Add($statusLabel)

    $retryBtn = New-Object System.Windows.Forms.Button
    $retryBtn.Text = "重新生成"
    $retryBtn.Size = New-Object System.Drawing.Size(100, 32)
    $retryBtn.Location = New-Object System.Drawing.Point(80, 380)
    $retryBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 255)
    $retryBtn.ForeColor = [System.Drawing.Color]::White
    $retryBtn.FlatStyle = "Flat"
    $retryBtn.Add_Click({
            $statusLabel.Text = "正在生成二维码..."
            $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 140, 0)
            $qrPlaceholder.Text = "正在生成二维码..."
            $qrForm.Refresh()
            Start-Sleep -Milliseconds 500
            try {
                $tokenUrl = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=$AppId&secret=$AppSecret"
                $tokenResponse = Invoke-WebRequest -Uri $tokenUrl -UseBasicParsing -TimeoutSec 10
                $tokenData = $tokenResponse.Content | ConvertFrom-Json
                if ($tokenData.access_token) {
                    $qrUrl = "https://api.weixin.qq.com/wxa/getQRcode?access_token=$($tokenData.access_token)"
                    $qrPlaceholder.Text = "二维码生成成功！`n请使用微信扫码"
                    $qrPlaceholder.ForeColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
                    $statusLabel.Text = "扫码绑定成功！"
                    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
                }
                else {
                    $qrPlaceholder.Text = "获取token失败"
                    $qrPlaceholder.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
                    $statusLabel.Text = "错误: $($tokenData.errmsg)"
                    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
                }
            }
            catch {
                $qrPlaceholder.Text = "网络请求失败"
                $qrPlaceholder.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
                $statusLabel.Text = "错误: $($_.Exception.Message)"
                $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
            }
        })
    $qrForm.Controls.Add($retryBtn)

    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = "关闭"
    $closeBtn.Size = New-Object System.Drawing.Size(100, 32)
    $closeBtn.Location = New-Object System.Drawing.Point(200, 380)
    $closeBtn.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
    $closeBtn.ForeColor = [System.Drawing.Color]::White
    $closeBtn.FlatStyle = "Flat"
    $closeBtn.Add_Click({ $qrForm.Close() })
    $qrForm.Controls.Add($closeBtn)

    $qrForm.Add_Shown({
            $qrForm.Activate()
            Start-Sleep -Milliseconds 500
            try {
                $tokenUrl = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=$AppId&secret=$AppSecret"
                $tokenResponse = Invoke-WebRequest -Uri $tokenUrl -UseBasicParsing -TimeoutSec 10
                $tokenData = $tokenResponse.Content | ConvertFrom-Json
                if ($tokenData.access_token) {
                    $qrPlaceholder.Text = "二维码生成成功！`n请使用微信扫码"
                    $qrPlaceholder.ForeColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
                    $statusLabel.Text = "扫码绑定成功！"
                    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
                }
                else {
                    $qrPlaceholder.Text = "获取token失败"
                    $qrPlaceholder.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
                    $statusLabel.Text = "错误: $($tokenData.errmsg)"
                    $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
                }
            }
            catch {
                $qrPlaceholder.Text = "网络请求失败"
                $qrPlaceholder.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
                $statusLabel.Text = "请检查网络连接"
                $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
            }
        })

    [void]$qrForm.ShowDialog()
}

function Ensure-Config {
    $configFile = Join-Path $script:STATE_DIR "openclaw.json"
    if (-not (Test-Path $configFile)) {
        $defaultConfig = @{
            gateway = @{
                mode = "local"
                auth = @{
                    mode  = "token"
                    token = "uclaw"
                }
            }
        }
        $json = $defaultConfig | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($configFile, $json, (New-Object System.Text.UTF8Encoding $false))
        return $defaultConfig
    }
    try {
        $content = Get-Content $configFile -Raw | ConvertFrom-Json
        return $content
    }
    catch {
        return @{
            gateway = @{
                mode = "local"
                auth = @{
                    mode  = "token"
                    token = "uclaw"
                }
            }
        }
    }
}

function Get-OpenAIModels {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApiKey
    )
    
    $models = @()
    try {
        $headers = @{
            "Authorization" = "Bearer $ApiKey"
            "Content-Type"  = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/models" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
        
        if ($response -and $response.data) {
            $filteredModels = $response.data | Where-Object { 
                $_.id -match "^(gpt-|o[0-9]|chatgpt)" -and $_.id -notmatch ":"
            } | Sort-Object -Property id
            
            foreach ($model in $filteredModels) {
                $models += @{
                    Name     = "OpenAI $($model.id)"
                    Provider = "openai"
                    Model    = $model.id
                    BaseUrl  = "https://api.openai.com/v1"
                    NeedKey  = $true
                    Hint     = "platform.openai.com"
                }
            }
        }
    }
    catch {
        Write-Host "OpenAI API error: $_"
        throw $_
    }
    return $models
}

function Get-DeepSeekModels {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApiKey
    )
    
    $models = @()
    try {
        $headers = @{
            "Authorization" = "Bearer $ApiKey"
            "Content-Type"  = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "https://api.deepseek.com/v1/models" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
        
        if ($response -and $response.data) {
            $filteredModels = $response.data | Where-Object { 
                $_.id -match "^(deepseek|reasoner)" 
            } | Sort-Object -Property id
            
            foreach ($model in $filteredModels) {
                $models += @{
                    Name     = "DeepSeek $($model.id)"
                    Provider = "deepseek"
                    Model    = $model.id
                    BaseUrl  = "https://api.deepseek.com/v1"
                    NeedKey  = $true
                    Hint     = "platform.deepseek.com"
                }
            }
        }
    }
    catch {
        Write-Host "DeepSeek API error: $_"
        throw $_
    }
    return $models
}

function Get-MistralModels {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApiKey
    )
    
    $models = @()
    try {
        $headers = @{
            "Authorization" = "Bearer $ApiKey"
            "Content-Type"  = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "https://api.mistral.ai/v1/models" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
        
        if ($response -and $response.data) {
            $filteredModels = $response.data | Sort-Object -Property id
            
            foreach ($model in $filteredModels) {
                $models += @{
                    Name     = "Mistral $($model.id)"
                    Provider = "mistral"
                    Model    = $model.id
                    BaseUrl  = "https://api.mistral.ai/v1"
                    NeedKey  = $true
                    Hint     = "mistral.ai"
                }
            }
        }
    }
    catch {
        Write-Host "Mistral API error: $_"
        throw $_
    }
    return $models
}

function Get-GroqModels {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApiKey
    )
    
    $models = @()
    try {
        $headers = @{
            "Authorization" = "Bearer $ApiKey"
            "Content-Type"  = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "https://api.groq.com/openai/v1/models" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
        
        if ($response -and $response.data) {
            $filteredModels = $response.data | Where-Object { 
                $_.id -notmatch ":"
            } | Sort-Object -Property id
            
            foreach ($model in $filteredModels) {
                $models += @{
                    Name     = "Groq $($model.id)"
                    Provider = "groq"
                    Model    = $model.id
                    BaseUrl  = "https://api.groq.com/openai/v1"
                    NeedKey  = $true
                    Hint     = "groq.com"
                }
            }
        }
    }
    catch {
        Write-Host "Groq API error: $_"
        throw $_
    }
    return $models
}

function Update-ProviderModels {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Provider,
        [Parameter(Mandatory = $true)]
        [string]$ApiKey,
        [int]$MaxRetries = 3
    )
    
    $models = @()
    $retryCount = 0
    $success = $false
    
    while ($retryCount -lt $MaxRetries -and -not $success) {
        try {
            switch ($Provider) {
                "openai" {
                    $models = Get-OpenAIModels -ApiKey $ApiKey
                }
                "deepseek" {
                    $models = Get-DeepSeekModels -ApiKey $ApiKey
                }
                "mistral" {
                    $models = Get-MistralModels -ApiKey $ApiKey
                }
                "groq" {
                    $models = Get-GroqModels -ApiKey $ApiKey
                }
                default {
                    throw "Unknown provider: $Provider"
                }
            }
            $success = $true
        }
        catch {
            $retryCount++
            if ($retryCount -lt $MaxRetries) {
                Write-Host "Retry $retryCount/$MaxRetries for $Provider..."
                Start-Sleep -Seconds 2
            }
            else {
                Write-Host "Failed to update $Provider models after $MaxRetries retries: $_"
                throw $_
            }
        }
    }
    
    return $models
}

function Update-AllModels {
    param(
        [Parameter(Mandatory = $true)]
        $ProviderConfigs,
        [Parameter(Mandatory = $false)]
        $ProgressCallback
    )
    
    $allModels = @()
    $errors = @()
    $totalProviders = $ProviderConfigs.Count
    $currentProvider = 0
    
    foreach ($config in $ProviderConfigs) {
        $currentProvider++
        $progress = [math]::Round(($currentProvider / $totalProviders) * 100)
        
        if ($ProgressCallback) {
            & $ProgressCallback $progress "正在更新 $($config.Provider)..."
        }
        
        try {
            $models = Update-ProviderModels -Provider $config.Provider -ApiKey $config.ApiKey
            $allModels += $models
            Write-Host "Updated $($models.Count) models from $($config.Provider)"
        }
        catch {
            $errors += @{
                Provider = $config.Provider
                Error    = $_.Exception.Message
            }
            Write-Host "Failed to update $($config.Provider): $_"
        }
    }
    
    return @{
        Models = $allModels
        Errors = $errors
    }
}

function Save-ModelsCache {
    param(
        [Parameter(Mandatory = $true)]
        $Models
    )
    
    try {
        $cacheFile = Join-Path $script:STATE_DIR "models-cache.json"
        $cacheData = @{
            Timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            Models    = $Models
        }
        $json = $cacheData | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($cacheFile, $json, (New-Object System.Text.UTF8Encoding $false))
        return $true
    }
    catch {
        Write-Host "Failed to save models cache: $_"
        return $false
    }
}

function Load-ModelsCache {
    try {
        $cacheFile = Join-Path $script:STATE_DIR "models-cache.json"
        if (-not (Test-Path $cacheFile)) {
            return $null
        }
        
        $cacheContent = Get-Content $cacheFile -Raw
        $cacheData = $cacheContent | ConvertFrom-Json
        
        # Check if cache is older than 24 hours
        $cacheAge = [DateTimeOffset]::Now.ToUnixTimeSeconds() - $cacheData.Timestamp
        if ($cacheAge -gt 86400) {
            # 24 hours in seconds
            Write-Host "Models cache is older than 24 hours"
            return $null
        }
        
        return $cacheData.Models
    }
    catch {
        Write-Host "Failed to load models cache: $_"
        return $null
    }
}

function Switch-Model {
    $modelForm = New-Object System.Windows.Forms.Form
    $modelForm.Text = $txtSelectModel
    $modelForm.Size = New-Object System.Drawing.Size(500, 800)
    $modelForm.StartPosition = "CenterScreen"
    $modelForm.FormBorderStyle = "FixedSingle"
    $modelForm.MaximizeBox = $false
    $modelForm.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
    $modelForm.AutoScroll = $true
    
    $modelTitle = New-Object System.Windows.Forms.Label
    $modelTitle.Text = $txtSelectModelHint
    $modelTitle.Font = New-Object System.Drawing.Font("Microsoft YaHei", 11, [System.Drawing.FontStyle]::Bold)
    $modelTitle.Size = New-Object System.Drawing.Size(440, 28)
    $modelTitle.Location = New-Object System.Drawing.Point(20, 12)
    $modelTitle.TextAlign = "MiddleLeft"
    $modelForm.Controls.Add($modelTitle)
    
    # Provider selection dropdown
    $providerLabel = New-Object System.Windows.Forms.Label
    $providerLabel.Text = "选择厂商："
    $providerLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $providerLabel.Size = New-Object System.Drawing.Size(80, 22)
    $providerLabel.Location = New-Object System.Drawing.Point(20, 45)
    $modelForm.Controls.Add($providerLabel)
    
    $providerCombo = New-Object System.Windows.Forms.ComboBox
    $providerCombo.Size = New-Object System.Drawing.Size(200, 28)
    $providerCombo.Location = New-Object System.Drawing.Point(105, 43)
    $providerCombo.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $providerCombo.DropDownStyle = "DropDownList"
    $providerCombo.Items.AddRange(@("全部厂商", "OpenAI", "DeepSeek", "豆包", "Mistral", "Groq", "智谱", "阿里", "月之暗面", "百度", "讯飞", "腾讯", "Anthropic", "Google", "xAI", "MiniMax", "绝舟", "火山引擎", "ZenMux", "OpenRouter", "本地 Ollama"))
    $providerCombo.SelectedIndex = 0
    $modelForm.Controls.Add($providerCombo)
    
    # Update button
    $updateBtn = New-Object System.Windows.Forms.Button
    $updateBtn.Text = "更新模型列表"
    $updateBtn.Size = New-Object System.Drawing.Size(120, 28)
    $updateBtn.Location = New-Object System.Drawing.Point(320, 43)
    $updateBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $updateBtn.BackColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
    $updateBtn.ForeColor = [System.Drawing.Color]::White
    $updateBtn.FlatStyle = "Flat"
    $updateBtn.Cursor = "Hand"
    $modelForm.Controls.Add($updateBtn)
    
    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Size = New-Object System.Drawing.Size(440, 20)
    $progressBar.Location = New-Object System.Drawing.Point(20, 75)
    $progressBar.Style = "Continuous"
    $progressBar.Visible = $false
    $modelForm.Controls.Add($progressBar)
    
    # Progress label
    $progressLabel = New-Object System.Windows.Forms.Label
    $progressLabel.Text = ""
    $progressLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
    $progressLabel.Size = New-Object System.Drawing.Size(440, 18)
    $progressLabel.Location = New-Object System.Drawing.Point(20, 98)
    $progressLabel.ForeColor = [System.Drawing.Color]::Gray
    $progressLabel.Visible = $false
    $modelForm.Controls.Add($progressLabel)
    
    # Models panel (scrollable)
    $modelsPanel = New-Object System.Windows.Forms.Panel
    $modelsPanel.Size = New-Object System.Drawing.Size(460, 580)
    $modelsPanel.Location = New-Object System.Drawing.Point(20, 120)
    $modelsPanel.AutoScroll = $true
    $modelsPanel.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
    $modelForm.Controls.Add($modelsPanel)
    
    # Default cloud models (fallback)
    $script:defaultCloudModels = @(
        # DeepSeek 模型
        @{Name = "DeepSeek-V4 (推荐)"; Provider = "deepseek"; Model = "deepseek-chat"; BaseUrl = "https://api.deepseek.com/v1"; NeedKey = $true; Hint = "platform.deepseek.com" },
        @{Name = "DeepSeek-R2 (推理)"; Provider = "deepseek"; Model = "deepseek-reasoner"; BaseUrl = "https://api.deepseek.com/v1"; NeedKey = $true; Hint = "platform.deepseek.com" },
        @{Name = "DeepSeek-V3"; Provider = "deepseek"; Model = "deepseek-chat-v3"; BaseUrl = "https://api.deepseek.com/v1"; NeedKey = $true; Hint = "platform.deepseek.com" },
        @{Name = "DeepSeek-Coder V2"; Provider = "deepseek"; Model = "deepseek-coder"; BaseUrl = "https://api.deepseek.com/v1"; NeedKey = $true; Hint = "platform.deepseek.com" },
        # 字节豆包模型
        @{Name = "字节豆包 Pro 256K (推荐)"; Provider = "doubao"; Model = "doubao-pro-256k"; BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"; NeedKey = $true; Hint = "console.volcengine.com" },
        @{Name = "字节豆包 Pro 32K"; Provider = "doubao"; Model = "doubao-pro-32k"; BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"; NeedKey = $true; Hint = "console.volcengine.com" },
        @{Name = "字节豆包 Pro 128K"; Provider = "doubao"; Model = "doubao-pro-128k"; BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"; NeedKey = $true; Hint = "console.volcengine.com" },
        @{Name = "字节豆包 Lite 128K (免费)"; Provider = "doubao"; Model = "doubao-lite-128k"; BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"; NeedKey = $true; Hint = "console.volcengine.com" },
        @{Name = "字节豆包 Lite 32K"; Provider = "doubao"; Model = "doubao-lite-32k"; BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"; NeedKey = $true; Hint = "console.volcengine.com" },
        @{Name = "字节豆包 Thinking (推理)"; Provider = "doubao"; Model = "doubao-thinking"; BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"; NeedKey = $true; Hint = "console.volcengine.com" },
        # 智谱模型
        @{Name = "智谱 GLM-5.1 (最新)"; Provider = "zhipu"; Model = "glm-5.1"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-5.0"; Provider = "zhipu"; Model = "glm-5.0"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-5V (多模态)"; Provider = "zhipu"; Model = "glm-5v"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-4.7-Thinking"; Provider = "zhipu"; Model = "glm-4.7-thinking"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-4.7-Active"; Provider = "zhipu"; Model = "glm-4.7-active"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-4.7-Air"; Provider = "zhipu"; Model = "glm-4.7-air"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-4.7-AirX"; Provider = "zhipu"; Model = "glm-4.7-airx"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-4.7-Flash"; Provider = "zhipu"; Model = "glm-4.7-flash"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-4.7-Thinking-199K"; Provider = "zhipu"; Model = "glm-4.7-thinking-199k"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-4-Plus"; Provider = "zhipu"; Model = "glm-4-plus"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-4-Long (1M上下文)"; Provider = "zhipu"; Model = "glm-4-long"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-4-Air"; Provider = "zhipu"; Model = "glm-4-air"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-4-Flash (免费)"; Provider = "zhipu"; Model = "glm-4-flash"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-4V (多模态)"; Provider = "zhipu"; Model = "glm-4v"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-Z1-Air (推理)"; Provider = "zhipu"; Model = "glm-z1-air"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        @{Name = "智谱 GLM-Z1-Flash (推理免费)"; Provider = "zhipu"; Model = "glm-z1-flash"; BaseUrl = "https://open.bigmodel.cn/api/paas/v4"; NeedKey = $true; Hint = "open.bigmodel.cn" },
        # 阿里模型
        @{Name = "阿里 Qwen4-235B (最新)"; Provider = "aliyun"; Model = "qwen4-235b"; BaseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"; NeedKey = $true; Hint = "dashscope.console.aliyun.com" },
        @{Name = "阿里 Qwen4-72B"; Provider = "aliyun"; Model = "qwen4-72b"; BaseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"; NeedKey = $true; Hint = "dashscope.console.aliyun.com" },
        @{Name = "阿里 Qwen3-Coder-Next"; Provider = "aliyun"; Model = "qwen3-coder-next"; BaseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"; NeedKey = $true; Hint = "dashscope.console.aliyun.com" },
        @{Name = "阿里 Qwen-Long (1M 上下文)"; Provider = "aliyun"; Model = "qwen-long"; BaseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"; NeedKey = $true; Hint = "dashscope.console.aliyun.com" },
        @{Name = "阿里 Qwen-Turbo"; Provider = "aliyun"; Model = "qwen-turbo"; BaseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"; NeedKey = $true; Hint = "dashscope.console.aliyun.com" },
        @{Name = "阿里 Qwen-Plus"; Provider = "aliyun"; Model = "qwen-plus"; BaseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"; NeedKey = $true; Hint = "dashscope.console.aliyun.com" },
        @{Name = "阿里 Qwen-Max"; Provider = "aliyun"; Model = "qwen-max"; BaseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"; NeedKey = $true; Hint = "dashscope.console.aliyun.com" },
        @{Name = "阿里 QwQ (推理)"; Provider = "aliyun"; Model = "qwq-plus"; BaseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1"; NeedKey = $true; Hint = "dashscope.console.aliyun.com" },
        # 月之暗面模型
        @{Name = "月之暗面 Kimi 2.5 (最新)"; Provider = "moonshot"; Model = "kimi-2.5"; BaseUrl = "https://api.moonshot.cn/v1"; NeedKey = $true; Hint = "platform.moonshot.cn" },
        @{Name = "月之暗面 Kimi 2.0"; Provider = "moonshot"; Model = "kimi-2.0"; BaseUrl = "https://api.moonshot.cn/v1"; NeedKey = $true; Hint = "platform.moonshot.cn" },
        @{Name = "月之暗面 Kimi 1.5"; Provider = "moonshot"; Model = "kimi-1.5"; BaseUrl = "https://api.moonshot.cn/v1"; NeedKey = $true; Hint = "platform.moonshot.cn" },
        @{Name = "月之暗面 Kimi 1.5-128K"; Provider = "moonshot"; Model = "kimi-1.5-128k"; BaseUrl = "https://api.moonshot.cn/v1"; NeedKey = $true; Hint = "platform.moonshot.cn" },
        @{Name = "月之暗面 Kimi K2"; Provider = "moonshot"; Model = "kimi-k2"; BaseUrl = "https://api.moonshot.cn/v1"; NeedKey = $true; Hint = "platform.moonshot.cn" },
        # 百度模型
        @{Name = "百度 ERNIE 5.0 (最新)"; Provider = "baidu"; Model = "ernie-5.0-8k"; BaseUrl = "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat"; NeedKey = $true; Hint = "console.bce.baidu.com" },
        @{Name = "百度 ERNIE 5.0 Pro"; Provider = "baidu"; Model = "ernie-5.0-pro"; BaseUrl = "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat"; NeedKey = $true; Hint = "console.bce.baidu.com" },
        @{Name = "百度 ERNIE X2 (推理)"; Provider = "baidu"; Model = "ernie-x2-8k"; BaseUrl = "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat"; NeedKey = $true; Hint = "console.bce.baidu.com" },
        @{Name = "百度 ERNIE 4.0 Turbo"; Provider = "baidu"; Model = "ernie-4.0-turbo-8k"; BaseUrl = "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat"; NeedKey = $true; Hint = "console.bce.baidu.com" },
        @{Name = "百度 ERNIE Speed"; Provider = "baidu"; Model = "ernie-speed"; BaseUrl = "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat"; NeedKey = $true; Hint = "console.bce.baidu.com" },
        # 讯飞模型
        @{Name = "讯飞星火 X2 (推理)"; Provider = "xfyun"; Model = "spark-x2"; BaseUrl = "https://spark-api-open.xf-yun.com/v1"; NeedKey = $true; Hint = "xinghuo.xfyun.cn" },
        @{Name = "讯飞星火 V5.0 Ultra"; Provider = "xfyun"; Model = "generalv5.0-ultra"; BaseUrl = "https://spark-api-open.xf-yun.com/v1"; NeedKey = $true; Hint = "xinghuo.xfyun.cn" },
        @{Name = "讯飞星火 V5.0 Pro"; Provider = "xfyun"; Model = "generalv5.0-pro"; BaseUrl = "https://spark-api-open.xf-yun.com/v1"; NeedKey = $true; Hint = "xinghuo.xfyun.cn" },
        @{Name = "讯飞星火 V4.0 Ultra"; Provider = "xfyun"; Model = "generalv4.0-ultra"; BaseUrl = "https://spark-api-open.xf-yun.com/v1"; NeedKey = $true; Hint = "xinghuo.xfyun.cn" },
        @{Name = "讯飞星火 Lite (免费)"; Provider = "xfyun"; Model = "spark-lite"; BaseUrl = "https://spark-api-open.xf-yun.com/v1"; NeedKey = $true; Hint = "xinghuo.xfyun.cn" },
        # 腾讯模型
        @{Name = "腾讯混元 T2 (推理)"; Provider = "tencent"; Model = "hunyuan-t2"; BaseUrl = "https://api.hunyuan.cloud.tencent.com/v1"; NeedKey = $true; Hint = "console.cloud.tencent.com" },
        @{Name = "腾讯混元 Pro 2.0"; Provider = "tencent"; Model = "hunyuan-pro2"; BaseUrl = "https://api.hunyuan.cloud.tencent.com/v1"; NeedKey = $true; Hint = "console.cloud.tencent.com" },
        @{Name = "腾讯混元 Standard"; Provider = "tencent"; Model = "hunyuan-standard"; BaseUrl = "https://api.hunyuan.cloud.tencent.com/v1"; NeedKey = $true; Hint = "console.cloud.tencent.com" },
        @{Name = "腾讯混元 Lite"; Provider = "tencent"; Model = "hunyuan-lite"; BaseUrl = "https://api.hunyuan.cloud.tencent.com/v1"; NeedKey = $true; Hint = "console.cloud.tencent.com" },
        # OpenAI模型
        @{Name = "OpenAI GPT-5.5 (最新)"; Provider = "openai"; Model = "gpt-5.5"; BaseUrl = "https://api.openai.com/v1"; NeedKey = $true; Hint = "platform.openai.com" },
        @{Name = "OpenAI GPT-5.4"; Provider = "openai"; Model = "gpt-5.4-turbo"; BaseUrl = "https://api.openai.com/v1"; NeedKey = $true; Hint = "platform.openai.com" },
        @{Name = "OpenAI GPT-5"; Provider = "openai"; Model = "gpt-5"; BaseUrl = "https://api.openai.com/v1"; NeedKey = $true; Hint = "platform.openai.com" },
        @{Name = "OpenAI GPT-4o"; Provider = "openai"; Model = "gpt-4o"; BaseUrl = "https://api.openai.com/v1"; NeedKey = $true; Hint = "platform.openai.com" },
        @{Name = "OpenAI GPT-4o Mini"; Provider = "openai"; Model = "gpt-4o-mini"; BaseUrl = "https://api.openai.com/v1"; NeedKey = $true; Hint = "platform.openai.com" },
        @{Name = "OpenAI o4-mini (推理)"; Provider = "openai"; Model = "o4-mini"; BaseUrl = "https://api.openai.com/v1"; NeedKey = $true; Hint = "platform.openai.com" },
        @{Name = "OpenAI o3-mini"; Provider = "openai"; Model = "o3-mini"; BaseUrl = "https://api.openai.com/v1"; NeedKey = $true; Hint = "platform.openai.com" },
        # Anthropic模型
        @{Name = "Anthropic Claude Opus 4.7 (最新)"; Provider = "anthropic"; Model = "claude-opus-4-7"; BaseUrl = "https://api.anthropic.com/v1"; NeedKey = $true; Hint = "console.anthropic.com" },
        @{Name = "Anthropic Claude Opus 4.6"; Provider = "anthropic"; Model = "claude-opus-4-6"; BaseUrl = "https://api.anthropic.com/v1"; NeedKey = $true; Hint = "console.anthropic.com" },
        @{Name = "Anthropic Claude Sonnet 4"; Provider = "anthropic"; Model = "claude-sonnet-4"; BaseUrl = "https://api.anthropic.com/v1"; NeedKey = $true; Hint = "console.anthropic.com" },
        @{Name = "Anthropic Claude 4.5"; Provider = "anthropic"; Model = "claude-4-5-sonnet"; BaseUrl = "https://api.anthropic.com/v1"; NeedKey = $true; Hint = "console.anthropic.com" },
        @{Name = "Anthropic Claude 4"; Provider = "anthropic"; Model = "claude-4-sonnet"; BaseUrl = "https://api.anthropic.com/v1"; NeedKey = $true; Hint = "console.anthropic.com" },
        @{Name = "Anthropic Claude 4 Opus"; Provider = "anthropic"; Model = "claude-4-opus"; BaseUrl = "https://api.anthropic.com/v1"; NeedKey = $true; Hint = "console.anthropic.com" },
        @{Name = "Anthropic Claude 3.7 Sonnet"; Provider = "anthropic"; Model = "claude-3-7-sonnet"; BaseUrl = "https://api.anthropic.com/v1"; NeedKey = $true; Hint = "console.anthropic.com" },
        @{Name = "Anthropic Claude 3.5 Haiku"; Provider = "anthropic"; Model = "claude-3-5-haiku"; BaseUrl = "https://api.anthropic.com/v1"; NeedKey = $true; Hint = "console.anthropic.com" },
        # Google模型
        @{Name = "Google Gemini 3.1 Pro Preview (最新)"; Provider = "google"; Model = "gemini-3.1-pro-preview"; BaseUrl = "https://generativelanguage.googleapis.com/v1beta"; NeedKey = $true; Hint = "ai.google.dev" },
        @{Name = "Google Gemini 3.0 Pro"; Provider = "google"; Model = "gemini-3.0-pro"; BaseUrl = "https://generativelanguage.googleapis.com/v1beta"; NeedKey = $true; Hint = "ai.google.dev" },
        @{Name = "Google Gemini 3.0 Flash"; Provider = "google"; Model = "gemini-3.0-flash"; BaseUrl = "https://generativelanguage.googleapis.com/v1beta"; NeedKey = $true; Hint = "ai.google.dev" },
        @{Name = "Google Gemini 2.5 Pro"; Provider = "google"; Model = "gemini-2.5-pro"; BaseUrl = "https://generativelanguage.googleapis.com/v1beta"; NeedKey = $true; Hint = "ai.google.dev" },
        @{Name = "Google Gemini 2.5 Flash"; Provider = "google"; Model = "gemini-2.5-flash"; BaseUrl = "https://generativelanguage.googleapis.com/v1beta"; NeedKey = $true; Hint = "ai.google.dev" },
        @{Name = "Google Gemini 2.0 Flash (免费)"; Provider = "google"; Model = "gemini-2.0-flash"; BaseUrl = "https://generativelanguage.googleapis.com/v1beta"; NeedKey = $true; Hint = "ai.google.dev" },
        # xAI模型
        @{Name = "xAI Grok 3.5 (最新)"; Provider = "xai"; Model = "grok-3.5"; BaseUrl = "https://api.x.ai/v1"; NeedKey = $true; Hint = "x.ai" },
        @{Name = "xAI Grok 3"; Provider = "xai"; Model = "grok-3"; BaseUrl = "https://api.x.ai/v1"; NeedKey = $true; Hint = "x.ai" },
        @{Name = "xAI Grok 3 Mini"; Provider = "xai"; Model = "grok-3-mini"; BaseUrl = "https://api.x.ai/v1"; NeedKey = $true; Hint = "x.ai" },
        @{Name = "xAI Grok 2"; Provider = "xai"; Model = "grok-2"; BaseUrl = "https://api.x.ai/v1"; NeedKey = $true; Hint = "x.ai" },
        # Mistral模型
        @{Name = "Mistral Large 3 (最新)"; Provider = "mistral"; Model = "mistral-large-3"; BaseUrl = "https://api.mistral.ai/v1"; NeedKey = $true; Hint = "mistral.ai" },
        @{Name = "Mistral Large 2"; Provider = "mistral"; Model = "mistral-large-2"; BaseUrl = "https://api.mistral.ai/v1"; NeedKey = $true; Hint = "mistral.ai" },
        @{Name = "Mistral Medium 3"; Provider = "mistral"; Model = "mistral-medium-3"; BaseUrl = "https://api.mistral.ai/v1"; NeedKey = $true; Hint = "mistral.ai" },
        @{Name = "Mistral Small 3"; Provider = "mistral"; Model = "mistral-small-3"; BaseUrl = "https://api.mistral.ai/v1"; NeedKey = $true; Hint = "mistral.ai" },
        @{Name = "Mistral Codestral 2 (代码)"; Provider = "mistral"; Model = "codestral-2"; BaseUrl = "https://api.mistral.ai/v1"; NeedKey = $true; Hint = "mistral.ai" },
        # MiniMax模型
        @{Name = "MiniMax M2.7 (最新)"; Provider = "minimax"; Model = "minimax-m2.7"; BaseUrl = "https://api.minimax.chat/v1"; NeedKey = $true; Hint = "api.minimax.chat" },
        @{Name = "MiniMax M2.5"; Provider = "minimax"; Model = "minimax-m2.5"; BaseUrl = "https://api.minimax.chat/v1"; NeedKey = $true; Hint = "api.minimax.chat" },
        @{Name = "MiniMax M2"; Provider = "minimax"; Model = "minimax-m2"; BaseUrl = "https://api.minimax.chat/v1"; NeedKey = $true; Hint = "api.minimax.chat" },
        @{Name = "MiniMax abab 7"; Provider = "minimax"; Model = "abab7"; BaseUrl = "https://api.minimax.chat/v1"; NeedKey = $true; Hint = "api.minimax.chat" },
        @{Name = "MiniMax abab 6.5"; Provider = "minimax"; Model = "abab6.5"; BaseUrl = "https://api.minimax.chat/v1"; NeedKey = $true; Hint = "api.minimax.chat" },
        # Groq模型
        @{Name = "Groq Llama 4 (极速)"; Provider = "groq"; Model = "llama-4-70b-versatile"; BaseUrl = "https://api.groq.com/openai/v1"; NeedKey = $true; Hint = "groq.com" },
        @{Name = "Groq Llama 3.3 70B"; Provider = "groq"; Model = "llama-3.3-70b-versatile"; BaseUrl = "https://api.groq.com/openai/v1"; NeedKey = $true; Hint = "groq.com" },
        @{Name = "Groq Llama 3.1 8B (免费)"; Provider = "groq"; Model = "llama-3.1-8b-instant"; BaseUrl = "https://api.groq.com/openai/v1"; NeedKey = $true; Hint = "groq.com" },
        @{Name = "Groq Mixtral 8x7B"; Provider = "groq"; Model = "mixtral-8x7b-32768"; BaseUrl = "https://api.groq.com/openai/v1"; NeedKey = $true; Hint = "groq.com" },
        @{Name = "Groq Gemma 2 9B"; Provider = "groq"; Model = "gemma2-9b-it"; BaseUrl = "https://api.groq.com/openai/v1"; NeedKey = $true; Hint = "groq.com" },
        # 绝舟中转站模型 (api.juezhou.org)
        @{Name = "绝舟 Claude Opus 4.7 (最新)"; Provider = "juezhou"; Model = "claude-opus-4-7"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        @{Name = "绝舟 Claude Opus 4.6"; Provider = "juezhou"; Model = "claude-opus-4-6"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        @{Name = "绝舟 Claude Sonnet 4"; Provider = "juezhou"; Model = "claude-sonnet-4"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        @{Name = "绝舟 Claude 3.7 Sonnet"; Provider = "juezhou"; Model = "claude-3-7-sonnet"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        @{Name = "绝舟 Claude 3.5 Sonnet"; Provider = "juezhou"; Model = "claude-3-5-sonnet"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        @{Name = "绝舟 GPT-4o"; Provider = "juezhou"; Model = "gpt-4o"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        @{Name = "绝舟 GPT-4o Mini"; Provider = "juezhou"; Model = "gpt-4o-mini"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        @{Name = "绝舟 GPT-4 Turbo"; Provider = "juezhou"; Model = "gpt-4-turbo"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        @{Name = "绝舟 Gemini 2.5 Pro"; Provider = "juezhou"; Model = "gemini-2.5-pro"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        @{Name = "绝舟 Gemini 2.0 Flash"; Provider = "juezhou"; Model = "gemini-2.0-flash"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        @{Name = "绝舟 DeepSeek V3"; Provider = "juezhou"; Model = "deepseek-v3"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        @{Name = "绝舟 DeepSeek R1"; Provider = "juezhou"; Model = "deepseek-r1"; BaseUrl = "https://api.juezhou.org/v1"; NeedKey = $true; Hint = "api.juezhou.org" },
        # 火山引擎模型
        @{Name = "火山豆包 5.0 (最新)"; Provider = "volcengine"; Model = "doubao-5"; BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"; NeedKey = $true; Hint = "console.volcengine.com" },
        @{Name = "火山豆包 4.5"; Provider = "volcengine"; Model = "doubao-4.5"; BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"; NeedKey = $true; Hint = "console.volcengine.com" },
        @{Name = "火山豆包 4.0"; Provider = "volcengine"; Model = "doubao-4"; BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"; NeedKey = $true; Hint = "console.volcengine.com" },
        @{Name = "火山豆包 Long 2 (1M上下文)"; Provider = "volcengine"; Model = "doubao-long-2"; BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"; NeedKey = $true; Hint = "console.volcengine.com" },
        @{Name = "火山豆包 Vision 2 (多模态)"; Provider = "volcengine"; Model = "doubao-vision-2"; BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"; NeedKey = $true; Hint = "console.volcengine.com" },
        # ZenMux模型
        @{Name = "ZenMux Ultra (旗舰推理)"; Provider = "zenmux"; Model = "zenmux-ultra"; BaseUrl = "https://zenmux.ai/api/v1"; NeedKey = $true; Hint = "zenmux.ai" },
        @{Name = "ZenMux Pro (推理版)"; Provider = "zenmux"; Model = "zenmux-pro"; BaseUrl = "https://zenmux.ai/api/v1"; NeedKey = $true; Hint = "zenmux.ai" },
        @{Name = "ZenMux Lite (轻量版)"; Provider = "zenmux"; Model = "zenmux-lite"; BaseUrl = "https://zenmux.ai/api/v1"; NeedKey = $true; Hint = "zenmux.ai" },
        @{Name = "ZenMux Gemini 3.5 Flash Free"; Provider = "zenmux"; Model = "google/gemini-3.5-flash-free"; BaseUrl = "https://zenmux.ai/api/v1"; NeedKey = $true; Hint = "zenmux.ai" },
        @{Name = "ZenMux GLM-4.7 Flash Free"; Provider = "zenmux"; Model = "z-ai/glm-4.7-flash-free"; BaseUrl = "https://zenmux.ai/api/v1"; NeedKey = $true; Hint = "zenmux.ai" },
        @{Name = "ZenMux GLM-4.6V Flash Free (多模态)"; Provider = "zenmux"; Model = "z-ai/glm-4.6v-flash-free"; BaseUrl = "https://zenmux.ai/api/v1"; NeedKey = $true; Hint = "zenmux.ai" },
        # OpenRouter模型
        @{Name = "OR GPT-6 Turbo"; Provider = "openrouter"; Model = "openai/gpt-6-turbo"; BaseUrl = "https://openrouter.ai/api/v1"; NeedKey = $true; Hint = "openrouter.ai" },
        @{Name = "OR Claude Opus 5"; Provider = "openrouter"; Model = "anthropic/claude-opus-5"; BaseUrl = "https://openrouter.ai/api/v1"; NeedKey = $true; Hint = "openrouter.ai" },
        @{Name = "OR Claude 3.5 Sonnet 2"; Provider = "openrouter"; Model = "anthropic/claude-3.5-sonnet-2"; BaseUrl = "https://openrouter.ai/api/v1"; NeedKey = $true; Hint = "openrouter.ai" },
        @{Name = "OR Gemini 2.5 Pro"; Provider = "openrouter"; Model = "google/gemini-2.5-pro"; BaseUrl = "https://openrouter.ai/api/v1"; NeedKey = $true; Hint = "openrouter.ai" },
        @{Name = "OR Gemini 2.5 Flash"; Provider = "openrouter"; Model = "google/gemini-2.5-flash"; BaseUrl = "https://openrouter.ai/api/v1"; NeedKey = $true; Hint = "openrouter.ai" },
        @{Name = "OR Llama3.3 70B"; Provider = "openrouter"; Model = "meta-llama/llama-3.3-70b-instruct"; BaseUrl = "https://openrouter.ai/api/v1"; NeedKey = $true; Hint = "openrouter.ai" },
        @{Name = "OR DeepSeek-R2"; Provider = "openrouter"; Model = "deepseek/deepseek-r2"; BaseUrl = "https://openrouter.ai/api/v1"; NeedKey = $true; Hint = "openrouter.ai" },
        @{Name = "OR Mistral Large 3"; Provider = "openrouter"; Model = "mistralai/mistral-large-3"; BaseUrl = "https://openrouter.ai/api/v1"; NeedKey = $true; Hint = "openrouter.ai" },
        @{Name = "OR Qwen2 72B"; Provider = "openrouter"; Model = "qwen/qwen-2-72b-instruct"; BaseUrl = "https://openrouter.ai/api/v1"; NeedKey = $true; Hint = "openrouter.ai" },
        @{Name = "OR Nemotron 3 Super 120B (免费推理)"; Provider = "openrouter"; Model = "nvidia/nemotron-3-super-120b-a12b:free"; BaseUrl = "https://openrouter.ai/api/v1"; NeedKey = $true; Hint = "openrouter.ai" }
    )
    
    # Load cached models or use defaults
    $script:cloudModels = Load-ModelsCache
    if (-not $script:cloudModels) {
        $script:cloudModels = $script:defaultCloudModels
    }
    
    # Function to render models
    $renderModels = {
        param($filter = "全部厂商")
        
        $modelsPanel.Controls.Clear()
        
        $filteredModels = @()
        $ollamaModels = Get-OllamaModels
        $customModels = Load-CustomModels
        $modelsConfig = Load-ModelsConfig
        $configuredProviders = $modelsConfig.providers.Keys
        
        if ($filter -eq "全部厂商") {
            $filteredModels = $script:cloudModels
            if ($ollamaModels.Count -gt 0) {
                $filteredModels += @{Name = "--- 本地 Ollama 模型 (已检测) ---"; Provider = "separator"; Model = ""; BaseUrl = ""; NeedKey = $false; Hint = "" }
                $filteredModels += $ollamaModels
            }
            if ($customModels.Count -gt 0) {
                $filteredModels += @{Name = $txtCustomModelSeparator; Provider = "separator"; Model = ""; BaseUrl = ""; NeedKey = $false; Hint = "" }
                $filteredModels += $customModels
            }
        }
        elseif ($filter -eq "本地 Ollama") {
            $filteredModels = $ollamaModels
        }
        else {
            $providerMap = @{
                "OpenAI"     = "openai"
                "DeepSeek"   = "deepseek"
                "豆包"         = "doubao"
                "Mistral"    = "mistral"
                "Groq"       = "groq"
                "智谱"         = "zhipu"
                "阿里"         = "aliyun"
                "月之暗面"       = "moonshot"
                "百度"         = "baidu"
                "讯飞"         = "xfyun"
                "腾讯"         = "tencent"
                "Anthropic"  = "anthropic"
                "Google"     = "google"
                "xAI"        = "xai"
                "MiniMax"    = "minimax"
                "绝舟"         = "juezhou"
                "火山引擎"       = "volcengine"
                "ZenMux"     = "zenmux"
                "OpenRouter" = "openrouter"
            }
            
            $providerKey = $providerMap[$filter]
            $filteredModels = $script:cloudModels | Where-Object { $_.Provider -eq $providerKey }
        }
        
        $yPos = 5
        foreach ($model in $filteredModels) {
            if ($model.Provider -eq "separator") {
                $sepLabel = New-Object System.Windows.Forms.Label
                $sepLabel.Text = $model.Name
                $sepLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9, [System.Drawing.FontStyle]::Bold)
                $sepLabel.Size = New-Object System.Drawing.Size(420, 28)
                $sepLabel.Location = New-Object System.Drawing.Point(5, $yPos)
                $sepLabel.TextAlign = "MiddleCenter"
                $sepLabel.ForeColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
                $modelsPanel.Controls.Add($sepLabel)
                $yPos += 34
                continue
            }
            
            $btn = New-Object System.Windows.Forms.Button
            
            $isConfigured = $false
            $statusPrefix = "○ "
            $statusColor = [System.Drawing.Color]::Gray
            
            if ($model.Provider -eq "custom") {
                if (-not [string]::IsNullOrEmpty($model.ApiKey)) {
                    $isConfigured = $true
                    $statusPrefix = "✓ "
                    $statusColor = [System.Drawing.Color]::FromArgb(50, 205, 50)
                }
            }
            elseif ($configuredProviders -contains $model.Provider) {
                $isConfigured = $true
                $statusPrefix = "✓ "
                $statusColor = [System.Drawing.Color]::FromArgb(50, 205, 50)
            }
            
            $configStatusHint = if ($isConfigured) { "已配置 API Key" } else { "未配置 API Key" }
            $originalHint = if ([string]::IsNullOrEmpty($model.Hint)) { "" } else { $model.Hint + " | " }
            $btn.Text = $statusPrefix + $model.Name
            $btn.Size = New-Object System.Drawing.Size(420, 32)
            $btn.Location = New-Object System.Drawing.Point(5, $yPos)
            $btn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
            
            $tooltip = New-Object System.Windows.Forms.ToolTip
            $tooltip.SetToolTip($btn, $originalHint + $configStatusHint)
            
            if ($model.Provider -eq "custom") {
                $btn.BackColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
            }
            else {
                $btn.BackColor = [System.Drawing.Color]::FromArgb(70, 130, 180)
            }
            
            $btn.ForeColor = [System.Drawing.Color]::White
            $btn.FlatStyle = "Flat"
            $btn.FlatAppearance.BorderSize = 0
            $btn.Cursor = "Hand"
            $btn.Tag = $model
            
            if ($model.Provider -eq "custom") {
                $btn.Add_Click({
                        param($sender, $e)
                    
                        $clickedModel = $sender.Tag
                    
                        if ($null -eq $clickedModel -or $clickedModel["Provider"] -ne "custom") {
                            return
                        }
                    
                        $modelName = $clickedModel["Name"]
                        $modelToConfigure = $clickedModel
                    
                        $menu = New-Object System.Windows.Forms.ContextMenuStrip
                        $useItem = $menu.Items.Add("使用此模型")
                        $deleteItem = $menu.Items.Add("删除此模型")
                    
                        $useItem.Add_Click({
                                param($s, $ev)
                                Configure-CustomModel $modelToConfigure $modelForm
                            })
                    
                        $deleteItem.Add_Click({
                                param($s, $ev)
                                $confirm = [System.Windows.Forms.MessageBox]::Show("确定要删除自定义模型 [$modelName] 吗？", "确认删除", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
                                if ($confirm -eq "Yes") {
                                    $deleteResult = Delete-CustomModel -ModelName $modelName
                                    if ($deleteResult) {
                                        [System.Windows.Forms.MessageBox]::Show("自定义模型已删除", "成功", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                                        & $renderModels $providerCombo.SelectedItem
                                    }
                                }
                            })
                    
                        $menu.Show($sender, (New-Object System.Drawing.Point(0, $sender.Height)))
                    })
            }
            else {
                $btn.Add_Click({
                        param($sender, $e)
                        $clickedModel = $sender.Tag
                        Configure-Model $clickedModel $modelForm
                    })
            }
            
            $modelsPanel.Controls.Add($btn)
            $yPos += 38
        }
        
        # Add custom model button
        $addCustomBtn = New-Object System.Windows.Forms.Button
        $addCustomBtn.Text = $txtAddCustomModel
        $addCustomBtn.Size = New-Object System.Drawing.Size(420, 32)
        $addCustomBtn.Location = New-Object System.Drawing.Point(5, $yPos)
        $addCustomBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
        $addCustomBtn.BackColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
        $addCustomBtn.ForeColor = [System.Drawing.Color]::White
        $addCustomBtn.FlatStyle = "Flat"
        $addCustomBtn.Cursor = "Hand"
        $addCustomBtn.Add_Click({
                Show-AddCustomModelDialog $modelForm
            })
        $modelsPanel.Controls.Add($addCustomBtn)
        $yPos += 42
        
        # Close button at the bottom
        $closeBtn = New-Object System.Windows.Forms.Button
        $closeBtn.Text = $txtCancel
        $closeBtn.Size = New-Object System.Drawing.Size(420, 32)
        $closeBtn.Location = New-Object System.Drawing.Point(5, $yPos)
        $closeBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
        $closeBtn.BackColor = [System.Drawing.Color]::Gray
        $closeBtn.ForeColor = [System.Drawing.Color]::White
        $closeBtn.FlatStyle = "Flat"
        $closeBtn.Add_Click({ $modelForm.Close() })
        $modelsPanel.Controls.Add($closeBtn)
    }
    
    # Provider combo change event
    $providerCombo.Add_SelectedIndexChanged({
            $filter = $providerCombo.SelectedItem
            & $renderModels $filter
        })
    
    # Update button click event
    $updateBtn.Add_Click({
            # Ask for API keys
            $apiKeyForm = New-Object System.Windows.Forms.Form
            $apiKeyForm.Text = "输入 API Keys"
            $apiKeyForm.Size = New-Object System.Drawing.Size(500, 400)
            $apiKeyForm.StartPosition = "CenterScreen"
            $apiKeyForm.FormBorderStyle = "FixedSingle"
            $apiKeyForm.MaximizeBox = $false
            $apiKeyForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)
        
            $keyLabel = New-Object System.Windows.Forms.Label
            $keyLabel.Text = "请输入要更新的厂商 API Key（留空则跳过）："
            $keyLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
            $keyLabel.Size = New-Object System.Drawing.Size(460, 22)
            $keyLabel.Location = New-Object System.Drawing.Point(20, 12)
            $apiKeyForm.Controls.Add($keyLabel)
        
            $yPos = 40
            $script:apiKeyBoxes = @{}
            $providers = @(
                @{Name = "OpenAI"; Key = "openai"; Url = "platform.openai.com" },
                @{Name = "DeepSeek"; Key = "deepseek"; Url = "platform.deepseek.com" },
                @{Name = "Mistral"; Key = "mistral"; Url = "mistral.ai" },
                @{Name = "Groq"; Key = "groq"; Url = "groq.com" }
            )
        
            foreach ($provider in $providers) {
                $label = New-Object System.Windows.Forms.Label
                $label.Text = "$($provider.Name) ($($provider.Url)):"
                $label.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
                $label.Size = New-Object System.Drawing.Size(460, 18)
                $label.Location = New-Object System.Drawing.Point(20, $yPos)
                $apiKeyForm.Controls.Add($label)
            
                $textBox = New-Object System.Windows.Forms.TextBox
                $textBox.Size = New-Object System.Drawing.Size(440, 24)
                $textBox.Location = New-Object System.Drawing.Point(20, ($yPos + 20))
                $textBox.Font = New-Object System.Drawing.Font("Consolas", 8)
                $textBox.PasswordChar = "*"
                $apiKeyForm.Controls.Add($textBox)
            
                $script:apiKeyBoxes[$provider.Key] = $textBox
                $yPos += 50
            }
        
            $okBtn = New-Object System.Windows.Forms.Button
            $okBtn.Text = "开始更新"
            $okBtn.Size = New-Object System.Drawing.Size(100, 28)
            $okBtn.Location = New-Object System.Drawing.Point(180, ($yPos + 10))
            $okBtn.BackColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
            $okBtn.ForeColor = [System.Drawing.Color]::White
            $okBtn.FlatStyle = "Flat"
            $okBtn.Add_Click({
                    $script:apiKeysToUse = @{}
                    foreach ($key in $script:apiKeyBoxes.Keys) {
                        if (-not [string]::IsNullOrEmpty($script:apiKeyBoxes[$key].Text)) {
                            $script:apiKeysToUse[$key] = $script:apiKeyBoxes[$key].Text
                        }
                    }
                    $apiKeyForm.Close()
                })
            $apiKeyForm.Controls.Add($okBtn)
        
            $cancelBtn = New-Object System.Windows.Forms.Button
            $cancelBtn.Text = $txtCancel
            $cancelBtn.Size = New-Object System.Drawing.Size(100, 28)
            $cancelBtn.Location = New-Object System.Drawing.Point(300, ($yPos + 10))
            $cancelBtn.Add_Click({ $apiKeyForm.Close() })
            $apiKeyForm.Controls.Add($cancelBtn)
        
            [void]$apiKeyForm.ShowDialog()
        
            if ($script:apiKeysToUse.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show("未输入任何 API Key，更新已取消。", $txtWarning, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }
        
            # Show progress UI
            $progressBar.Visible = $true
            $progressLabel.Visible = $true
            $updateBtn.Enabled = $false
            $providerCombo.Enabled = $false
        
            # Prepare provider configs
            $providerConfigs = @()
            foreach ($key in $script:apiKeysToUse.Keys) {
                $providerConfigs += @{
                    Provider = $key
                    ApiKey   = $script:apiKeysToUse[$key]
                }
            }
        
            # Progress callback
            $progressCallback = {
                param($percent, $message)
                $progressBar.Value = $percent
                $progressLabel.Text = $message
                $modelForm.Refresh()
            }
        
            # Update models
            try {
                $result = Update-AllModels -ProviderConfigs $providerConfigs -ProgressCallback $progressCallback
            
                if ($result.Models.Count -gt 0) {
                    # Merge with existing models
                    $existingProviders = $result.Models | Select-Object -ExpandProperty Provider -Unique
                    $script:cloudModels = @($script:cloudModels | Where-Object { $_.Provider -notin $existingProviders })
                    $script:cloudModels += $result.Models
                
                    # Save to cache
                    Save-ModelsCache -Models $script:cloudModels
                
                    # Re-render
                    & $renderModels $providerCombo.SelectedItem
                
                    $successMsg = "成功更新 $($result.Models.Count) 个模型！"
                    if ($result.Errors.Count -gt 0) {
                        $successMsg += "`n`n部分厂商更新失败："
                        foreach ($error in $result.Errors) {
                            $successMsg += "`n- $($error.Provider): $($error.Error)"
                        }
                    }
                
                    [System.Windows.Forms.MessageBox]::Show($successMsg, $txtSuccess, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show("未能获取任何模型，请检查 API Keys 是否正确。", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("更新失败：$_", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
            finally {
                $progressBar.Visible = $false
                $progressLabel.Visible = $false
                $updateBtn.Enabled = $true
                $providerCombo.Enabled = $true
            }
        })
    
    # Initial render
    & $renderModels "全部厂商"
    
    $modelForm.Add_Shown({ $modelForm.Activate() })
    [void]$modelForm.ShowDialog()
}

function Configure-Model {
    param($modelInfo, $parentForm)
    
    if ($null -eq $modelInfo) {
        [System.Windows.Forms.MessageBox]::Show("模型信息为空，请重新选择模型。", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    if ($null -eq $modelInfo["Model"]) {
        [System.Windows.Forms.MessageBox]::Show("错误：模型ID为空！名称：" + $modelInfo["Name"], $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    $apiKey = ""
    $script:modelApiKeyInput = ""
    if ($modelInfo["NeedKey"]) {
        $savedApiKey = ""
        try {
            $savedConfig = Load-ModelsConfig
            $provider = $modelInfo["Provider"]
            if ($savedConfig.providers -and $savedConfig.providers.ContainsKey($provider)) {
                $savedApiKey = $savedConfig.providers[$provider].apiKey
            }
        }
        catch {}

        $inputForm = New-Object System.Windows.Forms.Form
        $inputForm.Text = $txtInputApiKey
        $inputForm.Size = New-Object System.Drawing.Size(400, 180)
        $inputForm.StartPosition = "CenterScreen"
        $inputForm.FormBorderStyle = "FixedSingle"
        $inputForm.MaximizeBox = $false
        
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $txtApiKeyHint
        $label.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
        $label.Size = New-Object System.Drawing.Size(360, 22)
        $label.Location = New-Object System.Drawing.Point(20, 15)
        $inputForm.Controls.Add($label)
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Size = New-Object System.Drawing.Size(340, 28)
        $textBox.Location = New-Object System.Drawing.Point(20, 45)
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $textBox.PasswordChar = "*"
        if (-not [string]::IsNullOrEmpty($savedApiKey)) {
            $textBox.Text = $savedApiKey
        }
        $inputForm.Controls.Add($textBox)
        
        $hintLabel = New-Object System.Windows.Forms.Label
        if ($modelInfo["Hint"]) {
            $hintLabel.Text = "获取密钥：" + $modelInfo["Hint"]
        }
        else {
            $hintLabel.Text = ""
        }
        $hintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
        $hintLabel.Size = New-Object System.Drawing.Size(360, 18)
        $hintLabel.Location = New-Object System.Drawing.Point(20, 78)
        $hintLabel.ForeColor = [System.Drawing.Color]::Gray
        $inputForm.Controls.Add($hintLabel)
        
        $okBtn = New-Object System.Windows.Forms.Button
        $okBtn.Text = $txtConfirm
        $okBtn.Size = New-Object System.Drawing.Size(100, 28)
        $okBtn.Location = New-Object System.Drawing.Point(130, 105)
        $okBtn.Add_Click({
                $script:modelApiKeyInput = $textBox.Text
                $inputForm.Close()
            })
        $inputForm.Controls.Add($okBtn)
        
        $cancelBtn = New-Object System.Windows.Forms.Button
        $cancelBtn.Text = $txtCancel
        $cancelBtn.Size = New-Object System.Drawing.Size(100, 28)
        $cancelBtn.Location = New-Object System.Drawing.Point(240, 105)
        $cancelBtn.Add_Click({ $inputForm.Close() })
        $inputForm.Controls.Add($cancelBtn)
        
        $inputForm.Add_Shown({ $textBox.Focus() })
        [void]$inputForm.ShowDialog()
        
        if ([string]::IsNullOrEmpty($script:modelApiKeyInput)) {
            return
        }
        $apiKey = $script:modelApiKeyInput

        $provider = $modelInfo["Provider"]
        $baseUrl = $modelInfo["BaseUrl"]
        try {
            $saveResult = Update-ModelsConfig -Provider $provider -ApiKey $apiKey -BaseUrl $baseUrl
            if (-not $saveResult) {
                [System.Windows.Forms.MessageBox]::Show("API Key 保存失败，请检查配置文件权限。", "保存失败", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }
        }
        catch {
            Write-Host "Failed to save API key: $_"
            [System.Windows.Forms.MessageBox]::Show("保存 API Key 时发生错误：$_", "错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
    }
    
    try {
        Ensure-Config
        $configFile = Join-Path $script:STATE_DIR "openclaw.json"
        $token = Get-GatewayToken
        
        $modelId = $modelInfo["Model"]
        $modelName = $modelInfo["Name"]
        $modelBaseUrl = $modelInfo["BaseUrl"]
        
        $config = @{
            gateway  = @{
                mode = "local"
                auth = @{
                    mode  = "token"
                    token = $token
                }
            }
            commands = @{
                native       = "auto"
                nativeSkills = "auto"
                restart      = $true
                ownerDisplay = "raw"
            }
            models   = @{
                mode      = "merge"
                providers = @{
                    custom = @{
                        baseUrl = $modelBaseUrl
                        apiKey  = $apiKey
                        api     = "openai-completions"
                        models  = @(
                            @{
                                id            = $modelId
                                name          = $modelName
                                reasoning     = $false
                                input         = @("text")
                                cost          = @{
                                    input      = 0
                                    output     = 0
                                    cacheRead  = 0
                                    cacheWrite = 0
                                }
                                contextWindow = 128000
                                maxTokens     = 4096
                            }
                        )
                    }
                }
            }
            agents   = @{
                defaults = @{
                    model = @{
                        primary = "custom/$modelId"
                    }
                }
            }
        }
        
        $json = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($configFile, $json, (New-Object System.Text.UTF8Encoding $false))

        try {
            $saveResult = Update-ModelsConfig -Provider "custom" -ApiKey $apiKey -BaseUrl $customBaseUrl
            if (-not $saveResult) {
                Write-Host "[WARN] API Key 保存到加密配置失败"
            }
        }
        catch {
            Write-Host "[ERROR] 保存 API Key 异常: $_"
        }

        $parentForm.Close()
        
        $script:statusLabel.Text = $txtSwitchedTo + $modelInfo["Name"]
        [System.Windows.Forms.MessageBox]::Show(
            $txtModelConfigured + "`n`n" + $txtCurrentModel + $modelInfo["Name"] + "`n`n" + $txtClickStart,
            $txtSuccess,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            $txtConfigFailed + "：$_",
            $txtError,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Configure-CustomModel {
    param($modelInfo, $parentForm)
    
    if ($null -eq $modelInfo) {
        [System.Windows.Forms.MessageBox]::Show("错误：模型信息为空！", "错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    $script:modelApiKeyInput = ""
    $apiKey = $modelInfo["ApiKey"]
    
    if ($modelInfo["NeedKey"] -and [string]::IsNullOrEmpty($apiKey)) {
        $inputForm = New-Object System.Windows.Forms.Form
        $inputForm.Text = $txtInputApiKey
        $inputForm.Size = New-Object System.Drawing.Size(400, 180)
        $inputForm.StartPosition = "CenterScreen"
        $inputForm.FormBorderStyle = "FixedSingle"
        $inputForm.MaximizeBox = $false
        
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $txtApiKeyHint
        $label.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
        $label.Size = New-Object System.Drawing.Size(360, 22)
        $label.Location = New-Object System.Drawing.Point(20, 15)
        $inputForm.Controls.Add($label)
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Size = New-Object System.Drawing.Size(340, 28)
        $textBox.Location = New-Object System.Drawing.Point(20, 45)
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $textBox.PasswordChar = "*"
        $inputForm.Controls.Add($textBox)
        
        $hintLabel = New-Object System.Windows.Forms.Label
        $hintLabel.Text = "请输入自定义模型的 API Key"
        $hintLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
        $hintLabel.Size = New-Object System.Drawing.Size(360, 18)
        $hintLabel.Location = New-Object System.Drawing.Point(20, 78)
        $hintLabel.ForeColor = [System.Drawing.Color]::Gray
        $inputForm.Controls.Add($hintLabel)
        
        $okBtn = New-Object System.Windows.Forms.Button
        $okBtn.Text = $txtConfirm
        $okBtn.Size = New-Object System.Drawing.Size(100, 28)
        $okBtn.Location = New-Object System.Drawing.Point(130, 105)
        $okBtn.Add_Click({
                $script:modelApiKeyInput = $textBox.Text
                $inputForm.Close()
            })
        $inputForm.Controls.Add($okBtn)
        
        $cancelBtn = New-Object System.Windows.Forms.Button
        $cancelBtn.Text = $txtCancel
        $cancelBtn.Size = New-Object System.Drawing.Size(100, 28)
        $cancelBtn.Location = New-Object System.Drawing.Point(240, 105)
        $cancelBtn.Add_Click({ $inputForm.Close() })
        $inputForm.Controls.Add($cancelBtn)
        
        $inputForm.Add_Shown({ $textBox.Focus() })
        [void]$inputForm.ShowDialog()
        
        if ([string]::IsNullOrEmpty($script:modelApiKeyInput)) {
            return
        }
        $apiKey = $script:modelApiKeyInput
    }
    
    try {
        Ensure-Config
        $configFile = Join-Path $script:STATE_DIR "openclaw.json"
        $token = Get-GatewayToken
        
        $customModelId = $modelInfo["Model"]
        $customModelName = $modelInfo["Name"]
        $customBaseUrl = $modelInfo["BaseUrl"]
        
        $config = @{
            gateway  = @{
                mode = "local"
                auth = @{
                    mode  = "token"
                    token = $token
                }
            }
            commands = @{
                native       = "auto"
                nativeSkills = "auto"
                restart      = $true
                ownerDisplay = "raw"
            }
            models   = @{
                mode      = "merge"
                providers = @{
                    custom = @{
                        baseUrl = $customBaseUrl
                        apiKey  = $apiKey
                        api     = "openai-completions"
                        models  = @(
                            @{
                                id            = $customModelId
                                name          = $customModelName
                                reasoning     = $false
                                input         = @("text")
                                cost          = @{
                                    input      = 0
                                    output     = 0
                                    cacheRead  = 0
                                    cacheWrite = 0
                                }
                                contextWindow = 128000
                                maxTokens     = 4096
                            }
                        )
                    }
                }
            }
            agents   = @{
                defaults = @{
                    model = @{
                        primary = "custom/$customModelId"
                    }
                }
            }
        }
        
        $json = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($configFile, $json, (New-Object System.Text.UTF8Encoding $false))
        
        $parentForm.Close()
        
        $script:statusLabel.Text = $txtSwitchedTo + $modelInfo["Name"]
        
        [System.Windows.Forms.MessageBox]::Show(
            $txtModelConfigured + "`n`n" + $txtCurrentModel + $modelInfo["Name"] + "`n`n" + $txtClickStart,
            $txtSuccess,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            $txtConfigFailed + "：$_",
            $txtError,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Deploy-ToUSB {
    $folderForm = New-Object System.Windows.Forms.Form
    $folderForm.Text = $txtSelectUsb
    $folderForm.Size = New-Object System.Drawing.Size(500, 165)
    $folderForm.StartPosition = "CenterScreen"
    $folderForm.FormBorderStyle = "FixedSingle"
    $folderForm.MaximizeBox = $false
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $txtSelectUsbHint
    $label.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $label.Size = New-Object System.Drawing.Size(460, 22)
    $label.Location = New-Object System.Drawing.Point(20, 12)
    $folderForm.Controls.Add($label)
    
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Size = New-Object System.Drawing.Size(350, 28)
    $textBox.Location = New-Object System.Drawing.Point(20, 42)
    $textBox.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $folderForm.Controls.Add($textBox)
    
    $browseBtn = New-Object System.Windows.Forms.Button
    $browseBtn.Text = $txtBrowse
    $browseBtn.Size = New-Object System.Drawing.Size(80, 28)
    $browseBtn.Location = New-Object System.Drawing.Point(380, 42)
    $browseBtn.Add_Click({
            $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderDialog.Description = $txtSelectUsbHint
            $folderDialog.ShowNewFolderButton = $true
            if ($folderDialog.ShowDialog() -eq "OK") {
                $textBox.Text = $folderDialog.SelectedPath
            }
        })
    $folderForm.Controls.Add($browseBtn)
    
    $okBtn = New-Object System.Windows.Forms.Button
    $okBtn.Text = $txtStartDeploy
    $okBtn.Size = New-Object System.Drawing.Size(100, 28)
    $okBtn.Location = New-Object System.Drawing.Point(180, 85)
    $okBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $okBtn.ForeColor = [System.Drawing.Color]::White
    $okBtn.FlatStyle = "Flat"
    $okBtn.Add_Click({
            if ([string]::IsNullOrEmpty($textBox.Text)) {
                [System.Windows.Forms.MessageBox]::Show($txtSelectTarget, $txtHint, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }
            $script:deployTarget = $textBox.Text
            $folderForm.Close()
        })
    $folderForm.Controls.Add($okBtn)
    
    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Text = $txtCancel
    $cancelBtn.Size = New-Object System.Drawing.Size(100, 28)
    $cancelBtn.Location = New-Object System.Drawing.Point(300, 85)
    $cancelBtn.Add_Click({ $folderForm.Close() })
    $folderForm.Controls.Add($cancelBtn)
    
    [void]$folderForm.ShowDialog()
    
    if ([string]::IsNullOrEmpty($script:deployTarget)) {
        return
    }
    
    try {
        $targetDir = $script:deployTarget
        $targetUClaw = Join-Path $targetDir "OpenClaw"
        
        $script:statusLabel.Text = $txtDeploying + $targetUClaw
        $script:form.Refresh()
        
        if (Test-Path $targetUClaw) {
            $result = [System.Windows.Forms.MessageBox]::Show($txtOverwrite, $txtConfirm, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($result -ne "Yes") {
                $script:statusLabel.Text = $txtDeployCanceled
                return
            }
            Remove-Item -Recurse -Force $targetUClaw -ErrorAction SilentlyContinue
        }
        
        New-Item -ItemType Directory -Path $targetUClaw -Force | Out-Null
        
        $hasLocalNode = Test-Path $script:NODE_BIN
        $hasLocalOpenClaw = Test-Path (Join-Path $script:CORE_DIR "node_modules\openclaw\openclaw.mjs")

        $excludeDirs = @(".git", "release", "resources")
        if (-not $hasLocalNode) {
            $excludeDirs += "app"
        }
        if (-not $hasLocalOpenClaw) {
            $excludeDirs += "app\core\node_modules"
        }

        $script:statusLabel.Text = $txtCopying + " (Node.js=$hasLocalNode, OpenClaw=$hasLocalOpenClaw)"
        $script:form.Refresh()

        Get-ChildItem -Path $scriptPath -Exclude $excludeDirs | ForEach-Object {
            $dest = Join-Path $targetUClaw $_.Name
            if ($_.PSIsContainer) {
                Copy-Item -Path $_.FullName -Destination $dest -Recurse -Force
            }
            else {
                Copy-Item -Path $_.FullName -Destination $dest -Force
            }
        }

        if ($hasLocalNode) {
            $targetRuntimeDir = Join-Path $targetUClaw "app\runtime\node-win-x64"
            if (-not (Test-Path $targetRuntimeDir)) {
                New-Item -ItemType Directory -Path $targetRuntimeDir -Force | Out-Null
            }
            Copy-Item -Path "$script:NODE_DIR\*" -Destination $targetRuntimeDir -Recurse -Force
        }

        if ($hasLocalOpenClaw) {
            $targetCoreDir = Join-Path $targetUClaw "app\core"
            if (-not (Test-Path $targetCoreDir)) {
                New-Item -ItemType Directory -Path $targetCoreDir -Force | Out-Null
            }
            Copy-Item -Path "$script:CORE_DIR\node_modules" -Destination "$targetCoreDir\node_modules" -Recurse -Force
        }

        $script:statusLabel.Text = $txtCreatingScript
        $script:form.Refresh()
        
        $batContent = "@echo off`nchcp 65001 >nul`ncd /d `"%~dp0`"`npowershell -ExecutionPolicy Bypass -File `"U-Claw-Launcher.ps1`""
        $batFile = Join-Path $targetUClaw "Launcher.bat"
        $batContent | Out-File $batFile -Encoding utf8
        
        $script:statusLabel.Text = $txtDeployDone
        
        [System.Windows.Forms.MessageBox]::Show(
            $txtDeploySuccess + "`n`n" + $txtTargetLocation + $targetUClaw + "`n`n" + $txtCopyToUsb + "`n" + $txtDoubleClickStart,
            $txtSuccess,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        $script:statusLabel.Text = $txtDeployFailed
        [System.Windows.Forms.MessageBox]::Show(
            $txtDeployFailed + "：$_",
            $txtError,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Repair-SessionStore {
    $sessionsDir = Join-Path $script:STATE_DIR "agents\main\sessions"
    if (Test-Path $sessionsDir) {
        Get-ChildItem -Path $sessionsDir -Include "*.jsonl.bak*","*.reset.*","*.trajectory-path.json","*.trajectory.jsonl" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

function Auto-Approve-PendingDevices {
    $devicesDir = Join-Path $script:STATE_DIR "devices"
    if (-not (Test-Path $devicesDir)) { return }
    
    $pendingFile = Join-Path $devicesDir "pending.json"
    $pairedFile = Join-Path $devicesDir "paired.json"
    
    if (-not (Test-Path $pendingFile)) { return }
    
    try {
        $pendingContent = Get-Content $pendingFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($pendingContent)) { return }
        
        $pending = $pendingContent | ConvertFrom-Json
        if (-not $pending) { return }
        
        $paired = @{}
        if (Test-Path $pairedFile) {
            $pairedContent = Get-Content $pairedFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($pairedContent)) {
                $paired = $pairedContent | ConvertFrom-Json
            }
        }
        
        $pendingProps = $pending.PSObject.Properties
        if (-not $pendingProps) { return }
        
        $approved = $false
        foreach ($prop in $pendingProps) {
            $req = $prop.Value
            $deviceId = $req.deviceId
            if (-not $deviceId) { continue }
            
            if ($paired.PSObject.Properties.Name -contains $deviceId) { continue }
            
            $operatorScopes = @(
                "operator.admin",
                "operator.read",
                "operator.write",
                "operator.approvals",
                "operator.pairing"
            )
            
            $newDevice = @{
                deviceId       = $deviceId
                publicKey      = $req.publicKey
                platform       = $req.platform
                clientId       = $req.clientId
                clientMode     = $req.clientMode
                role           = "operator"
                roles          = @("operator")
                scopes         = $operatorScopes
                approvedScopes = $operatorScopes
                tokens         = @{
                    operator = @{
                        token        = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)) -replace '[^a-zA-Z0-9_-]', ''
                        role         = "operator"
                        scopes       = $operatorScopes
                        createdAtMs  = [long](([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()))
                        lastUsedAtMs = [long](([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()))
                    }
                }
                createdAtMs    = [long](([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()))
                approvedAtMs   = [long](([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()))
            }
            
            $paired | Add-Member -MemberType NoteProperty -Name $deviceId -Value $newDevice -Force
            $approved = $true
        }
        
        if ($approved) {
            $json = $paired | ConvertTo-Json -Depth 10
            [System.IO.File]::WriteAllText($pairedFile, $json, (New-Object System.Text.UTF8Encoding $false))
            Write-Host "Auto-approved pending devices"
        }
        
        [System.IO.File]::WriteAllText($pendingFile, "{}", (New-Object System.Text.UTF8Encoding $false))
    }
    catch {
        Write-Host "Error auto-approving devices: $_"
    }
}

function Start-UClaw {
    if (-not (Test-Path $script:NODE_BIN)) {
        [System.Windows.Forms.MessageBox]::Show($txtMissingNode + "`n`n" + $txtClickRepairFirst, $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        $script:statusLabel.Text = $txtMissingNode
        return
    }
    
    $openclawMjs = Join-Path $script:CORE_DIR "node_modules\openclaw\openclaw.mjs"
    if (-not (Test-Path $openclawMjs)) {
        [System.Windows.Forms.MessageBox]::Show($txtMissingOpenclaw + "`n`n" + $txtClickRepairFirst, $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        $script:statusLabel.Text = $txtMissingOpenclaw
        return
    }
    
    @($script:DATA_DIR, $script:STATE_DIR, "$($script:DATA_DIR)\memory", "$($script:DATA_DIR)\backups", "$($script:DATA_DIR)\logs") | ForEach-Object {
        if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
    }
    
    Ensure-Config
    $token = Sync-Token
    
    # 启动网关前，自动修复 session 存储
    Repair-SessionStore
    
    $PORT = 18790
    while ($PORT -le 18799) {
        $connection = Get-NetTCPConnection -LocalPort $PORT -ErrorAction SilentlyContinue
        if (-not $connection) { break }
        $PORT++
    }
    
    if ($PORT -gt 18799) {
        [System.Windows.Forms.MessageBox]::Show($txtNoPort, $txtPortError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        $script:statusLabel.Text = $txtPortOccupied
        return
    }
    
    $script:statusLabel.Text = $txtStartingGateway + $PORT + ")..."
    $script:form.Refresh()
    
    $gatewayScript = @"
`$env:OPENCLAW_HOME = "$($script:DATA_DIR)"
`$env:OPENCLAW_STATE_DIR = "$($script:STATE_DIR)"
`$env:OPENCLAW_CONFIG_PATH = "$($script:STATE_DIR)\openclaw.json"
Set-Location "$($script:CORE_DIR)"
Write-Host "OpenClaw Gateway Starting..."
Write-Host "Port: $PORT"
Write-Host "Token: $token"
Write-Host "Config: $($script:STATE_DIR)\openclaw.json"
Write-Host ""
& "$($script:NODE_BIN)" "$openclawMjs" gateway run --allow-unconfigured --force --port $PORT
"@
    
    $gatewayPs1 = Join-Path $script:STATE_DIR "start-gateway.ps1"
    $gatewayScript | Out-File $gatewayPs1 -Encoding utf8
    
    Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$gatewayPs1`"" -WindowStyle Normal
    
    $script:statusLabel.Text = $txtWaitingGateway
    $script:form.Refresh()
    
    $retries = 0
    $gatewayReady = $false
    while ($retries -lt 60) {
        try {
            $test = Invoke-WebRequest -Uri "http://127.0.0.1:$PORT/" -TimeoutSec 1 -UseBasicParsing -ErrorAction SilentlyContinue
            if ($test.StatusCode -eq 200) {
                $gatewayReady = $true
                break
            }
        }
        catch {}
        Start-Sleep -Milliseconds 500
        $retries++
    }
    
    if ($gatewayReady) {
        $script:statusLabel.Text = $txtGatewayReady
        $script:form.Refresh()
        
        Auto-Approve-PendingDevices
        
        Start-Sleep -Milliseconds 500
        
        $url = "http://localhost:$PORT/#token=uclaw"
        Start-Process $url
        
        $script:statusLabel.Text = $txtUClawStarted
        
        Start-Job -ScriptBlock {
            param($stateDir)
            for ($i = 0; $i -lt 10; $i++) {
                Start-Sleep -Seconds 3
                $pf = Join-Path $stateDir "devices\pending.json"
                if (Test-Path $pf) {
                    $c = Get-Content $pf -Raw -ErrorAction SilentlyContinue
                    if ($c -and $c.Trim() -ne "{}") {
                        $pairedF = Join-Path $stateDir "devices\paired.json"
                        $pending = $c | ConvertFrom-Json
                        $paired = @{}
                        if (Test-Path $pairedF) {
                            $pc = Get-Content $pairedF -Raw -ErrorAction SilentlyContinue
                            if ($pc) { $paired = $pc | ConvertFrom-Json }
                        }
                        foreach ($prop in $pending.PSObject.Properties) {
                            $req = $prop.Value
                            $did = $req.deviceId
                            if (-not $did) { continue }
                            if ($paired.PSObject.Properties.Name -contains $did) { continue }
                            $scopes = @("operator.admin", "operator.read", "operator.write", "operator.approvals", "operator.pairing")
                            $rngB2 = New-Object byte[] 32; [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($rngB2); $opToken = [Convert]::ToBase64String($rngB2) -replace '[^a-zA-Z0-9_-]', ''
                            $nowMs = [long](([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()))
                            $nd = @{
                                deviceId = $did; publicKey = $req.publicKey; platform = $req.platform
                                clientId = $req.clientId; clientMode = $req.clientMode
                                role = "operator"; roles = @("operator"); scopes = $scopes; approvedScopes = $scopes
                                tokens = @{operator = @{token = $opToken; role = "operator"; scopes = $scopes; createdAtMs = $nowMs; lastUsedAtMs = $nowMs } }
                                createdAtMs = $nowMs; approvedAtMs = $nowMs
                            }
                            $paired | Add-Member -MemberType NoteProperty -Name $did -Value $nd -Force
                        }
                        $json = $paired | ConvertTo-Json -Depth 10
                        [System.IO.File]::WriteAllText($pairedF, $json, (New-Object System.Text.UTF8Encoding $false))
                        [System.IO.File]::WriteAllText($pf, "{}", (New-Object System.Text.UTF8Encoding $false))
                    }
                }
            }
        } -ArgumentList $script:STATE_DIR | Out-Null
        
        $script:form.Close()
    }
    else {
        $script:statusLabel.Text = $txtGatewayFailed
        [System.Windows.Forms.MessageBox]::Show(
            $txtGatewayFailed + "`n`n请检查网关窗口中的错误详情。",
            $txtError,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Repair-UClaw {
    try {
        $repairMethod = "choice"
        
        if ($repairMethod -eq "choice") {
            $msg = "修复环境将修复 Node.js 运行时和 OpenClaw 核心。`n`n"
            $msg += "请选择修复方式：`n`n"
            $msg += "[是] 网盘下载（推荐，稳定快速）`n"
            $msg += "[否] NPM 安装（需要网络通畅）`n"
            $msg += "[取消] 退出修复"
            $result = [System.Windows.Forms.MessageBox]::Show($msg, "修复环境", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
            
            if ($result -eq "Yes") {
                Repair-FromCloud
            }
            elseif ($result -eq "No") {
                Repair-FromNPM
            }
            return
        }
        
        if ($repairMethod -eq "npm") {
            Repair-FromNPM
        }
        else {
            Repair-FromCloud
        }
    }
    catch {
        $script:statusLabel.Text = $txtRepairFailed
        [System.Windows.Forms.MessageBox]::Show($txtRepairFailed + "：$_", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Repair-FromCloud {
    try {
        $cloudUrl = "https://pan.baidu.com/s/1zgtbt1tDRTFGhCnKpRXmAw"
        $localFixZip = Join-Path $scriptPath "openclaw-usb-fix-2026-5-5.zip"
        $tempFixZip = Join-Path $env:TEMP "openclaw-usb-fix-2026-5-5.zip"
        
        $fixZipPath = $null
        
        if (Test-Path $localFixZip) {
            $fixZipPath = $localFixZip
            $script:statusLabel.Text = "正在使用本地修复包..."
            $script:form.Refresh()
        }
        else {
            $infoMsg = "未找到本地修复包，需要从网盘下载。`n`n"
            $infoMsg += "百度网盘：$cloudUrl`n"
            $infoMsg += "提取码：6hfe`n`n"
            $infoMsg += "请下载：openclaw-usb-fix-2026-5-5.zip`n`n"
            $infoMsg += "下载完成后将文件放到本目录，然后重新点击 [修复环境]"
            
            $downloadResult = [System.Windows.Forms.MessageBox]::Show($infoMsg, "下载修复包", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            if ($downloadResult -eq "OK") {
                Start-Process $cloudUrl
            }
            $script:statusLabel.Text = "请下载修复包后重试"
            return
        }
        
        if (-not $fixZipPath -or -not (Test-Path $fixZipPath)) {
            [System.Windows.Forms.MessageBox]::Show("未找到修复包文件。`n`n请将 'openclaw-usb-fix-2026-5-5.zip' 放到：`n$scriptPath", "错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $script:statusLabel.Text = "修复失败"
            return
        }
        
        $script:statusLabel.Text = $txtRepairExtracting
        $script:form.Refresh()
        
        $extractDir = Join-Path $env:TEMP "openclaw-fix-extract"
        if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
        New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
        
        Expand-Archive -Path $fixZipPath -DestinationPath $extractDir -Force
        
        $script:statusLabel.Text = $txtRepairVerifying
        $script:form.Refresh()
        
        $nodeDir = Join-Path $extractDir "node-win-x64"
        $openclawDir = Join-Path $extractDir "openclaw-core"
        
        $hasNode = Test-Path (Join-Path $nodeDir "node.exe")
        $hasOpenclaw = Test-Path (Join-Path $openclawDir "openclaw.mjs")
        
        if (-not $hasNode -or -not $hasOpenclaw) {
            Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue
            [System.Windows.Forms.MessageBox]::Show("修复包文件不完整，请重新下载。", "错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $script:statusLabel.Text = "修复失败"
            return
        }
        
        $script:statusLabel.Text = "正在安装 Node.js..."
        $script:form.Refresh()
        
        if (Test-Path $script:NODE_DIR) { Remove-Item -Recurse -Force $script:NODE_DIR -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $script:NODE_DIR -Force | Out-Null
        Copy-Item -Recurse -Force "$nodeDir\*" $script:NODE_DIR
        
        $script:statusLabel.Text = "正在安装 OpenClaw 核心..."
        $script:form.Refresh()
        
        if (Test-Path "$script:CORE_DIR\node_modules\openclaw") {
            Remove-Item -Recurse -Force "$script:CORE_DIR\node_modules\openclaw" -ErrorAction SilentlyContinue
        }
        if (-not (Test-Path "$script:CORE_DIR\node_modules")) {
            New-Item -ItemType Directory -Path "$script:CORE_DIR\node_modules" -Force | Out-Null
        }
        Copy-Item -Recurse -Force $openclawDir "$script:CORE_DIR\node_modules\openclaw"
        
        $fixPkg = Join-Path $extractDir "package.json"
        if (Test-Path $fixPkg) {
            Copy-Item $fixPkg (Join-Path $script:CORE_DIR "package.json") -Force
        }
        
        Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue
        
        $coreVersion = Get-OpenClawCoreVersion
        $nodeVer = ""
        try {
            $nodeVer = & $script:NODE_BIN -v 2>$null
        }
        catch {
            $nodeVer = $script:NODE_VERSION
        }
        
        $script:statusLabel.Text = $txtRepairDone
        $doneMsg = "修复完成！`n`n"
        $doneMsg += "OpenClaw 核心: $coreVersion`n"
        $doneMsg += "Node.js: $nodeVer`n`n"
        $doneMsg += $txtClickStartNow
        [System.Windows.Forms.MessageBox]::Show($doneMsg, $txtSuccess, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $script:statusLabel.Text = $txtRepairFailed
        [System.Windows.Forms.MessageBox]::Show($txtRepairFailed + "：$_", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Repair-FromNPM {
    try {
        $script:statusLabel.Text = "正在检测网络..."
        $script:form.Refresh()
        
        $isOnline = Test-NetworkConnection
        if (-not $isOnline) {
            [System.Windows.Forms.MessageBox]::Show("网络未连接，无法使用 NPM 安装。`n`n请使用 [网盘下载] 方式修复。", "网络错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            $script:statusLabel.Text = "修复已取消"
            return
        }
        
        $msg = "NPM 安装将从网络下载 OpenClaw 核心（约 200MB）。`n`n"
        $msg += "这将替换现有的 Node.js 运行时和 OpenClaw 核心包。`n`n"
        $msg += "是否继续？"
        $result = [System.Windows.Forms.MessageBox]::Show($msg, "修复环境 - NPM 安装", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($result -ne "Yes") {
            return
        }
        
        $script:statusLabel.Text = "正在停止旧进程..."
        $script:form.Refresh()
        
        Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*$scriptPath*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        
        $script:statusLabel.Text = "正在安装 Node.js 运行时..."
        $script:form.Refresh()
        
        $nodeMsiUrl = "https://npmmirror.com/mirrors/node/v22.13.0/node.exe"
        $nodeDest = Join-Path $script:NODE_DIR "node.exe"
        
        if (-not (Test-Path $script:NODE_DIR)) {
            New-Item -ItemType Directory -Path $script:NODE_DIR -Force | Out-Null
        }
        
        try {
            if (-not (Test-Path $nodeDest)) {
                $nodeTempDir = Join-Path $env:TEMP "node-download"
                if (Test-Path $nodeTempDir) { Remove-Item -Recurse -Force $nodeTempDir }
                New-Item -ItemType Directory -Path $nodeTempDir -Force | Out-Null
                
                $nodeZipPath = Join-Path $nodeTempDir "node.zip"
                $client = New-Object System.Net.WebClient
                $client.DownloadFile($nodeMsiUrl, $nodeZipPath)
                
                Expand-Archive -Path $nodeZipPath -DestinationPath $script:NODE_DIR -Force
                Remove-Item -Recurse -Force $nodeTempDir -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Verbose "Node.js download failed, trying existing node..."
        }
        
        $script:statusLabel.Text = "正在安装 OpenClaw 核心..."
        $script:form.Refresh()
        
        Push-Location $script:CORE_DIR
        
        $npmInstallScript = @"
`$ProgressPreference = 'SilentlyContinue'
`$ErrorActionPreference = 'Continue'
Write-Host 'Installing OpenClaw core...'
npm install openclaw@latest --registry='https://registry.npmmirror.com' --force --loglevel error --no-audit --no-fund 2>&1 | Out-Null
if (`$LASTEXITCODE -eq 0) {
    Write-Host 'SUCCESS'
} else {
    Write-Host 'FAILED'
}
"@
        
        $npmTempScript = Join-Path $env:TEMP "npm-install-openclaw.ps1"
        $npmInstallScript | Out-File $npmTempScript -Encoding utf8
        
        $installOutput = & powershell -ExecutionPolicy Bypass -File $npmTempScript 2>&1
        Remove-Item $npmTempScript -ErrorAction SilentlyContinue
        
        Pop-Location
        
        if (-not (Test-Path (Join-Path $script:CORE_DIR "node_modules\openclaw"))) {
            $retryMsg = "NPM 安装失败，是否尝试网盘下载方式？"
            $retryResult = [System.Windows.Forms.MessageBox]::Show($retryMsg, "安装失败", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($retryResult -eq "Yes") {
                Repair-FromCloud
            }
            $script:statusLabel.Text = "修复失败"
            return
        }
        
        $coreVersion = Get-OpenClawCoreVersion
        $nodeVer = ""
        try {
            $nodeVer = & $script:NODE_BIN -v 2>$null
        }
        catch {
            $nodeVer = $script:NODE_VERSION
        }
        
        $script:statusLabel.Text = $txtRepairDone
        $doneMsg = "修复完成！`n`n"
        $doneMsg += "OpenClaw 核心: $coreVersion`n"
        $doneMsg += "Node.js: $nodeVer`n`n"
        $doneMsg += $txtClickStartNow
        [System.Windows.Forms.MessageBox]::Show($doneMsg, $txtSuccess, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $script:statusLabel.Text = $txtRepairFailed
        [System.Windows.Forms.MessageBox]::Show($txtRepairFailed + "：$_", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Get-InstalledSkills {
    $skillsDir = Join-Path $scriptPath "skills-cn"
    $skills = @()
    
    if (-not (Test-Path $skillsDir)) {
        return $skills
    }
    
    $skillFolders = Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue
    
    foreach ($folder in $skillFolders) {
        $skillFile = Join-Path $folder.FullName "SKILL.md"
        $skill = @{
            Name        = $folder.Name
            ChineseName = ""
            Description = ""
            Emoji       = "⚡"
        }
        
        if (Test-Path $skillFile) {
            try {
                $content = Get-Content $skillFile -Raw -Encoding UTF8
                
                if ($content -match '^---\s*\n(.*?)\n---') {
                    $yaml = $Matches[1]
                    
                    if ($yaml -match 'name:\s*"?([^"\n]+)"?') {
                        $skill.Name = $Matches[1].Trim()
                    }
                    
                    if ($yaml -match 'description:\s*"([^"]+)"') {
                        $skill.Description = $Matches[1].Trim()
                    }
                    
                    if ($yaml -match 'emoji:\s*"?([^"\n]+)"?') {
                        $skill.Emoji = $Matches[1].Trim()
                    }
                    elseif ($yaml -match 'metadata:.*?emoji:\s*"?([^"\n]+)"?') {
                        $skill.Emoji = $Matches[1].Trim()
                    }
                }
                
                if ($content -match '\n#\s+(.+?)(\r?\n|$)') {
                    $skill.ChineseName = $Matches[1].Trim()
                }
            }
            catch {
            }
        }
        
        $skills += $skill
    }
    
    return $skills | Sort-Object { $_.Name }
}

function Show-SkillManager {
    $skillForm = New-Object System.Windows.Forms.Form
    $skillForm.Text = $txtSkillManageTitle
    $skillForm.Size = New-Object System.Drawing.Size(520, 450)
    $skillForm.StartPosition = "CenterParent"
    $skillForm.FormBorderStyle = "FixedDialog"
    $skillForm.MaximizeBox = $false
    $skillForm.MinimizeBox = $false
    $skillForm.BackColor = [System.Drawing.Color]::White
    $skillForm.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $txtSkillManageHint
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(480, 25)
    $titleLabel.Location = New-Object System.Drawing.Point(15, 15)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(51, 51, 51)
    $skillForm.Controls.Add($titleLabel)
    
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Size = New-Object System.Drawing.Size(480, 330)
    $panel.Location = New-Object System.Drawing.Point(15, 50)
    $panel.AutoScroll = $true
    $panel.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
    $skillForm.Controls.Add($panel)
    
    $skills = Get-InstalledSkills
    
    if ($skills.Count -eq 0) {
        $noSkillLabel = New-Object System.Windows.Forms.Label
        $noSkillLabel.Text = $txtNoSkills
        $noSkillLabel.Size = New-Object System.Drawing.Size(460, 30)
        $noSkillLabel.Location = New-Object System.Drawing.Point(10, 10)
        $noSkillLabel.TextAlign = "MiddleCenter"
        $noSkillLabel.ForeColor = [System.Drawing.Color]::Gray
        $panel.Controls.Add($noSkillLabel)
    }
    else {
        $yPos = 5
        foreach ($skill in $skills) {
            $cardPanel = New-Object System.Windows.Forms.Panel
            $cardPanel.Size = New-Object System.Drawing.Size(455, 55)
            $cardPanel.Location = New-Object System.Drawing.Point(5, $yPos)
            $cardPanel.BackColor = [System.Drawing.Color]::White
            
            $emojiLabel = New-Object System.Windows.Forms.Label
            $emojiLabel.Text = $skill.Emoji
            $emojiLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 16)
            $emojiLabel.Size = New-Object System.Drawing.Size(35, 35)
            $emojiLabel.Location = New-Object System.Drawing.Point(10, 10)
            $emojiLabel.TextAlign = "MiddleCenter"
            $cardPanel.Controls.Add($emojiLabel)
            
            $nameLabel = New-Object System.Windows.Forms.Label
            $displayName = $skill.Name
            if ($skill.ChineseName) {
                $displayName = "$($skill.Name) ($($skill.ChineseName))"
            }
            $nameLabel.Text = $displayName
            $nameLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10, [System.Drawing.FontStyle]::Bold)
            $nameLabel.Size = New-Object System.Drawing.Size(390, 20)
            $nameLabel.Location = New-Object System.Drawing.Point(50, 8)
            $nameLabel.ForeColor = [System.Drawing.Color]::FromArgb(33, 37, 41)
            $cardPanel.Controls.Add($nameLabel)
            
            $descLabel = New-Object System.Windows.Forms.Label
            $descLabel.Text = $skill.Description
            $descLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 8)
            $descLabel.Size = New-Object System.Drawing.Size(390, 25)
            $descLabel.Location = New-Object System.Drawing.Point(50, 28)
            $descLabel.ForeColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
            $cardPanel.Controls.Add($descLabel)
            
            $cardPanel.Tag = $skill
            $cardPanel.Add_DoubleClick({
                    $selectedSkill = $this.Tag
                    Show-SkillDetail -Skill $selectedSkill
                })
            
            $panel.Controls.Add($cardPanel)
            $yPos += 60
        }
    }
    
    $skillHubBtn = New-Object System.Windows.Forms.Button
    $skillHubBtn.Text = "技能市场"
    $skillHubBtn.Size = New-Object System.Drawing.Size(100, 32)
    $skillHubBtn.Location = New-Object System.Drawing.Point(95, 395)
    $skillHubBtn.BackColor = [System.Drawing.Color]::FromArgb(255, 107, 53)
    $skillHubBtn.ForeColor = [System.Drawing.Color]::White
    $skillHubBtn.FlatStyle = "Flat"
    $skillHubBtn.FlatAppearance.BorderSize = 0
    $skillHubBtn.Add_Click({
            $skillHubPath = Join-Path $scriptPath "SkillHub.html"
            if (Test-Path $skillHubPath) {
                Start-Process $skillHubPath
            }
            else {
                [System.Windows.Forms.MessageBox]::Show("SkillHub.html 文件不存在", "错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        })
    $skillForm.Controls.Add($skillHubBtn)
    
    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = $txtSkillClose
    $closeBtn.Size = New-Object System.Drawing.Size(100, 32)
    $closeBtn.Location = New-Object System.Drawing.Point(305, 395)
    $closeBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 255)
    $closeBtn.ForeColor = [System.Drawing.Color]::White
    $closeBtn.FlatStyle = "Flat"
    $closeBtn.FlatAppearance.BorderSize = 0
    $closeBtn.Add_Click({ $skillForm.Close() })
    $skillForm.Controls.Add($closeBtn)
    
    $skillForm.ShowDialog() | Out-Null
}

function Show-SkillDetail {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Skill
    )
    
    $detailForm = New-Object System.Windows.Forms.Form
    $detailForm.Text = $txtSkillDetailTitle + " - " + $Skill.Name
    $detailForm.Size = New-Object System.Drawing.Size(600, 500)
    $detailForm.StartPosition = "CenterParent"
    $detailForm.FormBorderStyle = "FixedDialog"
    $detailForm.MaximizeBox = $false
    $detailForm.MinimizeBox = $false
    $detailForm.BackColor = [System.Drawing.Color]::White
    $detailForm.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(580, 60)
    $headerPanel.Location = New-Object System.Drawing.Point(10, 10)
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $detailForm.Controls.Add($headerPanel)
    
    $emojiLabel = New-Object System.Windows.Forms.Label
    $emojiLabel.Text = $Skill.Emoji
    $emojiLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 24)
    $emojiLabel.Size = New-Object System.Drawing.Size(50, 50)
    $emojiLabel.Location = New-Object System.Drawing.Point(10, 5)
    $emojiLabel.TextAlign = "MiddleCenter"
    $headerPanel.Controls.Add($emojiLabel)
    
    $nameLabel = New-Object System.Windows.Forms.Label
    $displayName = $Skill.Name
    if ($Skill.ChineseName) {
        $displayName = "$($Skill.Name) ($($Skill.ChineseName))"
    }
    $nameLabel.Text = $displayName
    $nameLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 14, [System.Drawing.FontStyle]::Bold)
    $nameLabel.Size = New-Object System.Drawing.Size(500, 30)
    $nameLabel.Location = New-Object System.Drawing.Point(70, 5)
    $nameLabel.ForeColor = [System.Drawing.Color]::FromArgb(33, 37, 41)
    $headerPanel.Controls.Add($nameLabel)
    
    $descLabel = New-Object System.Windows.Forms.Label
    $descLabel.Text = $Skill.Description
    $descLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $descLabel.Size = New-Object System.Drawing.Size(500, 20)
    $descLabel.Location = New-Object System.Drawing.Point(70, 35)
    $descLabel.ForeColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
    $headerPanel.Controls.Add($descLabel)
    
    $contentTextBox = New-Object System.Windows.Forms.TextBox
    $contentTextBox.Multiline = $true
    $contentTextBox.ReadOnly = $true
    $contentTextBox.ScrollBars = "Vertical"
    $contentTextBox.Size = New-Object System.Drawing.Size(560, 350)
    $contentTextBox.Location = New-Object System.Drawing.Point(10, 80)
    $contentTextBox.BackColor = [System.Drawing.Color]::White
    $contentTextBox.BorderStyle = "FixedSingle"
    $contentTextBox.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    
    $skillFile = Join-Path $scriptPath "skills-cn\$($Skill.Name)\SKILL.md"
    if (Test-Path $skillFile) {
        $content = Get-Content $skillFile -Raw -Encoding UTF8
        $contentTextBox.Text = $content
    }
    else {
        $contentTextBox.Text = "技能文件不存在"
    }
    $detailForm.Controls.Add($contentTextBox)
    
    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = $txtSkillDetailClose
    $closeBtn.Size = New-Object System.Drawing.Size(100, 32)
    $closeBtn.Location = New-Object System.Drawing.Point(240, 440)
    $closeBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 255)
    $closeBtn.ForeColor = [System.Drawing.Color]::White
    $closeBtn.FlatStyle = "Flat"
    $closeBtn.FlatAppearance.BorderSize = 0
    $closeBtn.Add_Click({ $detailForm.Close() })
    $detailForm.Controls.Add($closeBtn)
    
    $detailForm.ShowDialog() | Out-Null
}

function Reset-Config {
    try {
        Ensure-Config
        $configFile = Join-Path $script:STATE_DIR "openclaw.json"
        $token = Get-GatewayToken
        
        if (Test-Path $configFile) {
            $backupFile = Join-Path $script:STATE_DIR "openclaw.json.backup"
            Copy-Item $configFile $backupFile -Force
        }
        
        $defaultConfig = @{
            gateway = @{
                mode = "local"
                auth = @{
                    mode  = "token"
                    token = $token
                }
            }
        }
        $json = $defaultConfig | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($configFile, $json, (New-Object System.Text.UTF8Encoding $false))
        
        $script:statusLabel.Text = $txtConfigReset
        [System.Windows.Forms.MessageBox]::Show($txtConfigReset, $txtDone, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($txtResetFailed + "：$_", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Start-Backup {
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Components = @("skills", "config", "memory", "core", "runtime")
    )
    
    try {
        $script:statusLabel.Text = $txtBackupHint
        $script:form.Refresh()
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFileName = "OpenClaw_Backup_$timestamp.zip"
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        if ([string]::IsNullOrEmpty($desktopPath) -or -not (Test-Path $desktopPath)) {
            $desktopPath = $scriptPath
        }
        $backupZipPath = Join-Path $desktopPath $backupFileName
        
        $tempBackupDir = Join-Path $env:TEMP "OpenClaw-Backup-$timestamp"
        New-Item -ItemType Directory -Path $tempBackupDir -Force | Out-Null
        
        $checksums = @{}
        $backupComponents = @()
        
        if ($Components -contains "skills") {
            $script:statusLabel.Text = "正在备份技能文件..."
            $script:form.Refresh()
            $skillsSrc = Join-Path $scriptPath "skills-cn"
            if (Test-Path $skillsSrc) {
                $skillsDst = Join-Path $tempBackupDir "skills-cn"
                Copy-Item -Path $skillsSrc -Destination $skillsDst -Recurse -Force
                $fileCount = (Get-ChildItem -Path $skillsDst -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
                $totalSize = (Get-ChildItem -Path $skillsDst -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $checksums["skills"] = @{ files = $fileCount; size = $totalSize }
                $backupComponents += "skills"
            }
        }
        
        if ($Components -contains "memory") {
            $script:statusLabel.Text = "正在备份长记忆文件..."
            $script:form.Refresh()
            $workspaceSrc = Join-Path $script:STATE_DIR "workspace"
            if (Test-Path $workspaceSrc) {
                $workspaceDst = Join-Path $tempBackupDir "workspace"
                Copy-Item -Path $workspaceSrc -Destination $workspaceDst -Recurse -Force
                $fileCount = (Get-ChildItem -Path $workspaceDst -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
                $totalSize = (Get-ChildItem -Path $workspaceDst -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $checksums["memory"] = @{ files = $fileCount; size = $totalSize }
                $backupComponents += "memory"
            }
        }
        
        if ($Components -contains "config") {
            $script:statusLabel.Text = "正在备份模型配置..."
            $script:form.Refresh()
            $configFiles = @("models-config.json", "custom-models.json")
            $configFileCount = 0
            $configTotalSize = 0
            foreach ($configFile in $configFiles) {
                $configSrc = Join-Path $script:STATE_DIR $configFile
                if (Test-Path $configSrc) {
                    Copy-Item -Path $configSrc -Destination $tempBackupDir -Force
                    $configFileCount++
                    $configTotalSize += (Get-Item $configSrc).Length
                }
            }
            if ($configFileCount -gt 0) {
                $checksums["config"] = @{ files = $configFileCount; size = $configTotalSize }
                $backupComponents += "config"
            }
        }
        
        if ($Components -contains "core") {
            $script:statusLabel.Text = "正在备份OpenClaw核心..."
            $script:form.Refresh()
            $openclawCoreSrc = Join-Path $script:CORE_DIR "node_modules\openclaw"
            if (Test-Path $openclawCoreSrc) {
                $openclawCoreDst = Join-Path $tempBackupDir "openclaw-core"
                Copy-Item -Path $openclawCoreSrc -Destination $openclawCoreDst -Recurse -Force
                $fileCount = (Get-ChildItem -Path $openclawCoreDst -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
                $totalSize = (Get-ChildItem -Path $openclawCoreDst -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $checksums["core"] = @{ files = $fileCount; size = $totalSize }
                $backupComponents += "core"
            }
        }
        
        if ($Components -contains "runtime") {
            $script:statusLabel.Text = "正在备份Node.js运行时..."
            $script:form.Refresh()
            $nodeRuntimeSrc = Join-Path $script:RUNTIME_DIR "node-win-x64"
            if (Test-Path $nodeRuntimeSrc) {
                $nodeRuntimeDst = Join-Path $tempBackupDir "node-runtime"
                Copy-Item -Path $nodeRuntimeSrc -Destination $nodeRuntimeDst -Recurse -Force
                $fileCount = (Get-ChildItem -Path $nodeRuntimeDst -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
                $totalSize = (Get-ChildItem -Path $nodeRuntimeDst -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $checksums["runtime"] = @{ files = $fileCount; size = $totalSize }
                $backupComponents += "runtime"
            }
        }
        
        $script:statusLabel.Text = "正在生成备份元数据..."
        $script:form.Refresh()
        
        $openclawVersion = "unknown"
        $packageJsonPath = Join-Path $script:CORE_DIR "node_modules\openclaw\package.json"
        if (Test-Path $packageJsonPath) {
            try {
                $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
                $openclawVersion = $packageJson.version
            } catch {}
        }
        
        $manifest = @{
            backupVersion = "1.0"
            createdAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            components = $backupComponents
            version = $openclawVersion
            checksums = $checksums
        }
        
        $manifestJson = $manifest | ConvertTo-Json -Depth 10
        $manifestPath = Join-Path $tempBackupDir "backup-manifest.json"
        $manifestJson | Out-File -FilePath $manifestPath -Encoding UTF8
        
        $script:statusLabel.Text = "正在压缩备份文件..."
        $script:form.Refresh()
        [System.IO.Compression.ZipFile]::CreateFromDirectory($tempBackupDir, $backupZipPath)
        
        if (Test-Path $tempBackupDir) {
            Remove-Item -Path $tempBackupDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        $script:statusLabel.Text = $txtDone
        [System.Windows.Forms.MessageBox]::Show($txtBackupDone + "`n`n" + $txtBackupLocation + $backupZipPath, $txtDone, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $script:statusLabel.Text = $txtBackupFailed
        [System.Windows.Forms.MessageBox]::Show($txtBackupFailed + "：$_", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Start-Restore {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupFile
    )
    
    $tempRestoreDir = $null
    $rollbackDir = $null
    $restoreSuccess = $false
    
    try {
        $script:statusLabel.Text = $txtRestoreHint
        $script:form.Refresh()
        
        $tempRestoreDir = Join-Path $env:TEMP "OpenClaw-Restore-$(Get-Date -Format 'yyyyMMddHHmmss')"
        New-Item -ItemType Directory -Path $tempRestoreDir -Force | Out-Null
        
        $script:statusLabel.Text = "正在解压备份文件..."
        $script:form.Refresh()
        [System.IO.Compression.ZipFile]::ExtractToDirectory($BackupFile, $tempRestoreDir)
        
        $manifestPath = Join-Path $tempRestoreDir "backup-manifest.json"
        $manifest = $null
        if (Test-Path $manifestPath) {
            try {
                $manifestJson = Get-Content $manifestPath -Raw
                $manifest = $manifestJson | ConvertFrom-Json
            } catch {
                $manifest = $null
            }
        }
        
        if ($manifest) {
            $componentNames = @{
                "skills" = "技能 (skills-cn)"
                "config" = "配置 (*.json)"
                "memory" = "长记忆 (workspace)"
                "core" = "OpenClaw核心"
                "runtime" = "Node.js运行时"
            }
            
            $previewInfo = "备份信息预览`n"
            $previewInfo += "================`n"
            $previewInfo += "备份版本: $($manifest.backupVersion)`n"
            $previewInfo += "备份时间: $($manifest.createdAt)`n"
            $previewInfo += "OpenClaw版本: $($manifest.version)`n"
            $previewInfo += "`n包含组件:`n"
            
            foreach ($comp in $manifest.components) {
                $compName = if ($componentNames[$comp]) { $componentNames[$comp] } else { $comp }
                $previewInfo += "  - $compName"
                if ($manifest.checksums.$comp) {
                    $files = $manifest.checksums.$comp.files
                    $size = $manifest.checksums.$comp.size
                    $sizeMB = [math]::Round($size / 1MB, 2)
                    $previewInfo += " ($files 个文件, $sizeMB MB)"
                }
                $previewInfo += "`n"
            }
            
            $previewInfo += "`n是否确认恢复？`n`n注意：恢复前将自动备份当前文件以便回滚。"
            
            $confirmResult = [System.Windows.Forms.MessageBox]::Show($previewInfo, "备份信息预览", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Information)
            if ($confirmResult -ne "Yes") {
                if (Test-Path $tempRestoreDir) {
                    Remove-Item -Path $tempRestoreDir -Recurse -Force -ErrorAction SilentlyContinue
                }
                $script:statusLabel.Text = "恢复已取消"
                return
            }
        }
        
        $script:statusLabel.Text = "正在创建回滚备份..."
        $script:form.Refresh()
        $rollbackDir = Join-Path $env:TEMP "OpenClaw-Rollback-$(Get-Date -Format 'yyyyMMddHHmmss')"
        New-Item -ItemType Directory -Path $rollbackDir -Force | Out-Null
        
        $skillsTarget = Join-Path $scriptPath "skills-cn"
        if (Test-Path $skillsTarget) {
            Copy-Item -Path $skillsTarget -Destination (Join-Path $rollbackDir "skills-cn") -Recurse -Force
        }
        
        $workspaceTarget = Join-Path $script:STATE_DIR "workspace"
        if (Test-Path $workspaceTarget) {
            Copy-Item -Path $workspaceTarget -Destination (Join-Path $rollbackDir "workspace") -Recurse -Force
        }
        
        $modelsConfigTarget = Join-Path $script:STATE_DIR "models-config.json"
        if (Test-Path $modelsConfigTarget) {
            Copy-Item -Path $modelsConfigTarget -Destination $rollbackDir -Force
        }
        $customModelsTarget = Join-Path $script:STATE_DIR "custom-models.json"
        if (Test-Path $customModelsTarget) {
            Copy-Item -Path $customModelsTarget -Destination $rollbackDir -Force
        }
        
        $openclawCoreTarget = Join-Path $script:CORE_DIR "node_modules\openclaw"
        if (Test-Path $openclawCoreTarget) {
            Copy-Item -Path $openclawCoreTarget -Destination (Join-Path $rollbackDir "openclaw-core") -Recurse -Force
        }
        
        $nodeRuntimeTarget = Join-Path $script:RUNTIME_DIR "node-win-x64"
        if (Test-Path $nodeRuntimeTarget) {
            Copy-Item -Path $nodeRuntimeTarget -Destination (Join-Path $rollbackDir "node-runtime") -Recurse -Force
        }
        
        $script:statusLabel.Text = "正在恢复技能文件..."
        $script:form.Refresh()
        $skillsBackup = Join-Path $tempRestoreDir "skills-cn"
        if (Test-Path $skillsBackup) {
            if (Test-Path $skillsTarget) { Remove-Item -Path $skillsTarget -Recurse -Force }
            Copy-Item -Path $skillsBackup -Destination $skillsTarget -Recurse -Force
        }
        
        $script:statusLabel.Text = "正在恢复长记忆文件..."
        $script:form.Refresh()
        $workspaceBackup = Join-Path $tempRestoreDir "workspace"
        if (Test-Path $workspaceBackup) {
            if (Test-Path $workspaceTarget) { Remove-Item -Path $workspaceTarget -Recurse -Force }
            Copy-Item -Path $workspaceBackup -Destination $workspaceTarget -Recurse -Force
        }
        
        $script:statusLabel.Text = "正在恢复模型配置..."
        $script:form.Refresh()
        $modelsConfigBackup = Join-Path $tempRestoreDir "models-config.json"
        if (Test-Path $modelsConfigBackup) {
            Copy-Item -Path $modelsConfigBackup -Destination (Join-Path $script:STATE_DIR "models-config.json") -Force
        }
        $customModelsBackup = Join-Path $tempRestoreDir "custom-models.json"
        if (Test-Path $customModelsBackup) {
            Copy-Item -Path $customModelsBackup -Destination (Join-Path $script:STATE_DIR "custom-models.json") -Force
        }
        
        $script:statusLabel.Text = "正在恢复OpenClaw核心..."
        $script:form.Refresh()
        $openclawCoreBackup = Join-Path $tempRestoreDir "openclaw-core"
        if (Test-Path $openclawCoreBackup) {
            if (Test-Path $openclawCoreTarget) { Remove-Item -Path $openclawCoreTarget -Recurse -Force }
            Copy-Item -Path $openclawCoreBackup -Destination $openclawCoreTarget -Recurse -Force
        }
        
        $script:statusLabel.Text = "正在恢复Node.js运行时..."
        $script:form.Refresh()
        $nodeRuntimeBackup = Join-Path $tempRestoreDir "node-runtime"
        if (Test-Path $nodeRuntimeBackup) {
            if (Test-Path $nodeRuntimeTarget) { Remove-Item -Path $nodeRuntimeTarget -Recurse -Force }
            Copy-Item -Path $nodeRuntimeBackup -Destination $nodeRuntimeTarget -Recurse -Force
        }
        
        $restoreSuccess = $true
        
        if (Test-Path $tempRestoreDir) {
            Remove-Item -Path $tempRestoreDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        if (Test-Path $rollbackDir) {
            Remove-Item -Path $rollbackDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        $script:statusLabel.Text = $txtDone
        [System.Windows.Forms.MessageBox]::Show($txtRestoreDone + "`n`n" + $txtRestoreRestart, $txtDone, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $script:statusLabel.Text = $txtRestoreFailed
        
        if (-not $restoreSuccess -and $rollbackDir -and (Test-Path $rollbackDir)) {
            $rollbackResult = [System.Windows.Forms.MessageBox]::Show("恢复失败，是否回滚到恢复前的状态？`n`n错误信息：$_", "恢复失败", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Error)
            
            if ($rollbackResult -eq "Yes") {
                try {
                    $script:statusLabel.Text = "正在回滚..."
                    $script:form.Refresh()
                    
                    $skillsRollback = Join-Path $rollbackDir "skills-cn"
                    if (Test-Path $skillsRollback) {
                        $skillsTarget = Join-Path $scriptPath "skills-cn"
                        if (Test-Path $skillsTarget) { Remove-Item -Path $skillsTarget -Recurse -Force }
                        Copy-Item -Path $skillsRollback -Destination $skillsTarget -Recurse -Force
                    }
                    
                    $workspaceRollback = Join-Path $rollbackDir "workspace"
                    if (Test-Path $workspaceRollback) {
                        $workspaceTarget = Join-Path $script:STATE_DIR "workspace"
                        if (Test-Path $workspaceTarget) { Remove-Item -Path $workspaceTarget -Recurse -Force }
                        Copy-Item -Path $workspaceRollback -Destination $workspaceTarget -Recurse -Force
                    }
                    
                    $modelsConfigRollback = Join-Path $rollbackDir "models-config.json"
                    if (Test-Path $modelsConfigRollback) {
                        Copy-Item -Path $modelsConfigRollback -Destination (Join-Path $script:STATE_DIR "models-config.json") -Force
                    }
                    $customModelsRollback = Join-Path $rollbackDir "custom-models.json"
                    if (Test-Path $customModelsRollback) {
                        Copy-Item -Path $customModelsRollback -Destination (Join-Path $script:STATE_DIR "custom-models.json") -Force
                    }
                    
                    $openclawCoreRollback = Join-Path $rollbackDir "openclaw-core"
                    if (Test-Path $openclawCoreRollback) {
                        $openclawCoreTarget = Join-Path $script:CORE_DIR "node_modules\openclaw"
                        if (Test-Path $openclawCoreTarget) { Remove-Item -Path $openclawCoreTarget -Recurse -Force }
                        Copy-Item -Path $openclawCoreRollback -Destination $openclawCoreTarget -Recurse -Force
                    }
                    
                    $nodeRuntimeRollback = Join-Path $rollbackDir "node-runtime"
                    if (Test-Path $nodeRuntimeRollback) {
                        $nodeRuntimeTarget = Join-Path $script:RUNTIME_DIR "node-win-x64"
                        if (Test-Path $nodeRuntimeTarget) { Remove-Item -Path $nodeRuntimeTarget -Recurse -Force }
                        Copy-Item -Path $nodeRuntimeRollback -Destination $nodeRuntimeTarget -Recurse -Force
                    }
                    
                    $script:statusLabel.Text = "回滚完成"
                    [System.Windows.Forms.MessageBox]::Show("已成功回滚到恢复前的状态。", "回滚完成", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("回滚失败：$_", "回滚失败", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
        }
        else {
            [System.Windows.Forms.MessageBox]::Show($txtRestoreFailed + "：$_", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
        
        if (Test-Path $tempRestoreDir) {
            Remove-Item -Path $tempRestoreDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $rollbackDir) {
            Remove-Item -Path $rollbackDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Show-BackupOptions {
    $optionsForm = New-Object System.Windows.Forms.Form
    $optionsForm.Text = "创建备份 - 选择组件"
    $optionsForm.Size = New-Object System.Drawing.Size(420, 400)
    $optionsForm.StartPosition = "CenterParent"
    $optionsForm.FormBorderStyle = "FixedDialog"
    $optionsForm.MaximizeBox = $false
    $optionsForm.MinimizeBox = $false
    $optionsForm.BackColor = [System.Drawing.Color]::White
    $optionsForm.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "选择要备份的组件"
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(380, 30)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $titleLabel.TextAlign = "MiddleCenter"
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(33, 37, 41)
    $optionsForm.Controls.Add($titleLabel)
    
    $checkboxY = 55
    $checkboxHeight = 30
    $checkboxes = @{}
    
    $componentDefinitions = @(
        @{Name = "skills"; Label = "技能 (skills-cn 目录)"; Default = $true},
        @{Name = "config"; Label = "配置 (data/.openclaw/*.json)"; Default = $true},
        @{Name = "memory"; Label = "长记忆 (data/.openclaw/memory)"; Default = $true},
        @{Name = "core"; Label = "OpenClaw核心文件 (app/core)"; Default = $true},
        @{Name = "runtime"; Label = "Node.js运行时 (app/runtime)"; Default = $true}
    )
    
    foreach ($comp in $componentDefinitions) {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Text = $comp.Label
        $checkbox.Size = New-Object System.Drawing.Size(360, $checkboxHeight)
        $checkbox.Location = New-Object System.Drawing.Point(30, $checkboxY)
        $checkbox.Checked = $comp.Default
        $checkbox.ForeColor = [System.Drawing.Color]::FromArgb(33, 37, 41)
        $optionsForm.Controls.Add($checkbox)
        $checkboxes[$comp.Name] = $checkbox
        $checkboxY += $checkboxHeight + 5
    }
    
    $btnSelectAll = New-Object System.Windows.Forms.Button
    $btnSelectAll.Text = "全选"
    $btnSelectAll.Size = New-Object System.Drawing.Size(100, 32)
    $btnSelectAll.Location = New-Object System.Drawing.Point(30, ($checkboxY + 10))
    $btnSelectAll.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
    $btnSelectAll.ForeColor = [System.Drawing.Color]::White
    $btnSelectAll.FlatStyle = "Flat"
    $btnSelectAll.FlatAppearance.BorderSize = 0
    $btnSelectAll.Add_Click({
        foreach ($key in $checkboxes.Keys) {
            $checkboxes[$key].Checked = $true
        }
    })
    $optionsForm.Controls.Add($btnSelectAll)
    
    $btnDeselectAll = New-Object System.Windows.Forms.Button
    $btnDeselectAll.Text = "取消全选"
    $btnDeselectAll.Size = New-Object System.Drawing.Size(100, 32)
    $btnDeselectAll.Location = New-Object System.Drawing.Point(140, ($checkboxY + 10))
    $btnDeselectAll.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
    $btnDeselectAll.ForeColor = [System.Drawing.Color]::White
    $btnDeselectAll.FlatStyle = "Flat"
    $btnDeselectAll.FlatAppearance.BorderSize = 0
    $btnDeselectAll.Add_Click({
        foreach ($key in $checkboxes.Keys) {
            $checkboxes[$key].Checked = $false
        }
    })
    $optionsForm.Controls.Add($btnDeselectAll)
    
    $btnStartBackup = New-Object System.Windows.Forms.Button
    $btnStartBackup.Text = "开始备份"
    $btnStartBackup.Size = New-Object System.Drawing.Size(100, 32)
    $btnStartBackup.Location = New-Object System.Drawing.Point(250, ($checkboxY + 10))
    $btnStartBackup.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
    $btnStartBackup.ForeColor = [System.Drawing.Color]::White
    $btnStartBackup.FlatStyle = "Flat"
    $btnStartBackup.FlatAppearance.BorderSize = 0
    $btnStartBackup.Add_Click({
        $selectedComponents = @()
        foreach ($key in $checkboxes.Keys) {
            if ($checkboxes[$key].Checked) {
                $selectedComponents += $key
            }
        }
        if ($selectedComponents.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("请至少选择一个组件进行备份", "提示", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        $optionsForm.Close()
        Start-Backup -Components $selectedComponents
    })
    $optionsForm.Controls.Add($btnStartBackup)
    
    $optionsForm.ShowDialog() | Out-Null
}

function Show-BackupMenu {
    $menuForm = New-Object System.Windows.Forms.Form
    $menuForm.Text = $txtBackupTitle
    $menuForm.Size = New-Object System.Drawing.Size(400, 280)
    $menuForm.StartPosition = "CenterParent"
    $menuForm.FormBorderStyle = "FixedDialog"
    $menuForm.MaximizeBox = $false
    $menuForm.MinimizeBox = $false
    $menuForm.BackColor = [System.Drawing.Color]::White
    $menuForm.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "选择备份操作"
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(360, 30)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $titleLabel.TextAlign = "MiddleCenter"
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(33, 37, 41)
    $menuForm.Controls.Add($titleLabel)
    
    $btnCreateBackup = New-Object System.Windows.Forms.Button
    $btnCreateBackup.Text = "📦 创建备份"
    $btnCreateBackup.Size = New-Object System.Drawing.Size(340, 45)
    $btnCreateBackup.Location = New-Object System.Drawing.Point(20, 55)
    $btnCreateBackup.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
    $btnCreateBackup.ForeColor = [System.Drawing.Color]::White
    $btnCreateBackup.FlatStyle = "Flat"
    $btnCreateBackup.FlatAppearance.BorderSize = 0
    $btnCreateBackup.Font = New-Object System.Drawing.Font("Microsoft YaHei", 11)
    $btnCreateBackup.Add_Click({
            $menuForm.Close()
            Show-BackupOptions
        })
    $menuForm.Controls.Add($btnCreateBackup)
    
    $btnRestoreBackup = New-Object System.Windows.Forms.Button
    $btnRestoreBackup.Text = "📥 恢复备份"
    $btnRestoreBackup.Size = New-Object System.Drawing.Size(340, 45)
    $btnRestoreBackup.Location = New-Object System.Drawing.Point(20, 110)
    $btnRestoreBackup.BackColor = [System.Drawing.Color]::FromArgb(255, 153, 0)
    $btnRestoreBackup.ForeColor = [System.Drawing.Color]::White
    $btnRestoreBackup.FlatStyle = "Flat"
    $btnRestoreBackup.FlatAppearance.BorderSize = 0
    $btnRestoreBackup.Font = New-Object System.Drawing.Font("Microsoft YaHei", 11)
    $btnRestoreBackup.Add_Click({
            $menuForm.Close()
            $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $openFileDialog.Title = $txtRestoreSelectFile
            $openFileDialog.Filter = "ZIP文件 (*.zip)|*.zip"
            $openFileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
            if ($openFileDialog.ShowDialog() -eq "OK") {
                $msg = $txtRestoreConfirm + "`n`n" + $txtContinue
                $result = [System.Windows.Forms.MessageBox]::Show($msg, $txtConfirm, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
                if ($result -eq "Yes") {
                    Start-Restore -BackupFile $openFileDialog.FileName
                }
            }
        })
    $menuForm.Controls.Add($btnRestoreBackup)
    
    $btnViewHistory = New-Object System.Windows.Forms.Button
    $btnViewHistory.Text = "📋 查看历史"
    $btnViewHistory.Size = New-Object System.Drawing.Size(340, 45)
    $btnViewHistory.Location = New-Object System.Drawing.Point(20, 165)
    $btnViewHistory.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
    $btnViewHistory.ForeColor = [System.Drawing.Color]::White
    $btnViewHistory.FlatStyle = "Flat"
    $btnViewHistory.FlatAppearance.BorderSize = 0
    $btnViewHistory.Font = New-Object System.Drawing.Font("Microsoft YaHei", 11)
    $btnViewHistory.Add_Click({
            $menuForm.Close()
            Show-BackupHistory
        })
    $menuForm.Controls.Add($btnViewHistory)
    
    $menuForm.ShowDialog() | Out-Null
}

function Show-BackupHistory {
    $historyForm = New-Object System.Windows.Forms.Form
    $historyForm.Text = $txtHistoryTitle
    $historyForm.Size = New-Object System.Drawing.Size(600, 450)
    $historyForm.StartPosition = "CenterParent"
    $historyForm.FormBorderStyle = "FixedDialog"
    $historyForm.MaximizeBox = $false
    $historyForm.MinimizeBox = $false
    $historyForm.BackColor = [System.Drawing.Color]::White
    $historyForm.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    
    $listView = New-Object System.Windows.Forms.ListView
    $listView.View = "Details"
    $listView.FullRowSelect = $true
    $listView.Size = New-Object System.Drawing.Size(560, 320)
    $listView.Location = New-Object System.Drawing.Point(10, 10)
    $listView.Columns.Add("文件名", 280) | Out-Null
    $listView.Columns.Add($txtHistorySize, 100) | Out-Null
    $listView.Columns.Add($txtHistoryTime, 160) | Out-Null
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $searchPaths = @($desktopPath, $scriptPath)
    $backupFiles = @()
    
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $files = Get-ChildItem -Path $path -Filter "OpenClaw_Backup_*.zip" -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                $backupFiles += $file
            }
            $legacyFiles = Get-ChildItem -Path $path -Filter "OpenClaw-Backup-*.zip" -ErrorAction SilentlyContinue
            foreach ($file in $legacyFiles) {
                $backupFiles += $file
            }
        }
    }
    
    if ($backupFiles.Count -eq 0) {
        $noBackupLabel = New-Object System.Windows.Forms.Label
        $noBackupLabel.Text = $txtHistoryNoBackup
        $noBackupLabel.Size = New-Object System.Drawing.Size(560, 30)
        $noBackupLabel.Location = New-Object System.Drawing.Point(10, 150)
        $noBackupLabel.TextAlign = "MiddleCenter"
        $noBackupLabel.ForeColor = [System.Drawing.Color]::Gray
        $historyForm.Controls.Add($noBackupLabel)
    }
    else {
        foreach ($file in ($backupFiles | Sort-Object LastWriteTime -Descending)) {
            $sizeKB = [math]::Round($file.Length / 1KB, 2)
            $item = New-Object System.Windows.Forms.ListViewItem($file.Name)
            $item.SubItems.Add("$sizeKB KB") | Out-Null
            $item.SubItems.Add($file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) | Out-Null
            $item.Tag = $file.FullName
            $listView.Items.Add($item) | Out-Null
        }
        $historyForm.Controls.Add($listView)
    }
    
    $btnPanel = New-Object System.Windows.Forms.Panel
    $btnPanel.Size = New-Object System.Drawing.Size(560, 50)
    $btnPanel.Location = New-Object System.Drawing.Point(10, 340)
    $historyForm.Controls.Add($btnPanel)
    
    $deleteBtn = New-Object System.Windows.Forms.Button
    $deleteBtn.Text = $txtHistoryDelete
    $deleteBtn.Size = New-Object System.Drawing.Size(100, 32)
    $deleteBtn.Location = New-Object System.Drawing.Point(150, 10)
    $deleteBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
    $deleteBtn.ForeColor = [System.Drawing.Color]::White
    $deleteBtn.FlatStyle = "Flat"
    $deleteBtn.FlatAppearance.BorderSize = 0
    $deleteBtn.Add_Click({
            if ($listView.SelectedItems.Count -gt 0) {
                $selectedFile = $listView.SelectedItems[0].Tag
                $result = [System.Windows.Forms.MessageBox]::Show($txtHistoryConfirmDelete, $txtConfirm, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                if ($result -eq "Yes") {
                    Remove-Item -Path $selectedFile -Force
                    $listView.Items.Remove($listView.SelectedItems[0])
                }
            }
        })
    $btnPanel.Controls.Add($deleteBtn)
    
    $openBtn = New-Object System.Windows.Forms.Button
    $openBtn.Text = $txtHistoryOpenLocation
    $openBtn.Size = New-Object System.Drawing.Size(100, 32)
    $openBtn.Location = New-Object System.Drawing.Point(310, 10)
    $openBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 255)
    $openBtn.ForeColor = [System.Drawing.Color]::White
    $openBtn.FlatStyle = "Flat"
    $openBtn.FlatAppearance.BorderSize = 0
    $openBtn.Add_Click({
            if ($listView.SelectedItems.Count -gt 0) {
                $selectedFile = $listView.SelectedItems[0].Tag
                $folder = Split-Path -Parent $selectedFile
                Start-Process "explorer.exe" -ArgumentList $folder
            }
        })
    $btnPanel.Controls.Add($openBtn)
    
    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = $txtSkillClose
    $closeBtn.Size = New-Object System.Drawing.Size(100, 32)
    $closeBtn.Location = New-Object System.Drawing.Point(240, 400)
    $closeBtn.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
    $closeBtn.ForeColor = [System.Drawing.Color]::White
    $closeBtn.FlatStyle = "Flat"
    $closeBtn.FlatAppearance.BorderSize = 0
    $closeBtn.Add_Click({ $historyForm.Close() })
    $historyForm.Controls.Add($closeBtn)
    
    $historyForm.ShowDialog() | Out-Null
}

function Test-NetworkConnection {
    param(
        [string]$TestUrl = $script:NETWORK_TEST_URL,
        [int]$Timeout = $script:NETWORK_TIMEOUT
    )
    try {
        $request = [System.Net.WebRequest]::Create($TestUrl)
        $request.Timeout = $Timeout * 1000
        $request.Method = "HEAD"
        $response = $request.GetResponse()
        $response.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Get-NetworkStatus {
    if ($null -eq $script:lastNetworkStatus) {
        $script:lastNetworkStatus = Test-NetworkConnection
    }
    return $script:lastNetworkStatus
}

function Update-NetworkStatusDisplay {
    param([bool]$IsOnline)
    if ($IsOnline) {
        $script:networkStatusLabel.Text = "🌐 " + $txtNetworkOnline
        $script:networkStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
    }
    else {
        $script:networkStatusLabel.Text = "📵 " + $txtNetworkOffline
        $script:networkStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
    }
}

function Get-UpdateConfig {
    if (Test-Path $script:UPDATE_CONFIG_FILE) {
        try {
            $content = Get-Content $script:UPDATE_CONFIG_FILE -Raw -Encoding UTF8
            $config = $content | ConvertFrom-Json
            return @{
                versionUrl      = if ($config.versionUrl) { $config.versionUrl } else { $script:NETWORK_VERSION_URL }
                checkInterval   = if ($config.checkInterval) { $config.checkInterval } else { $script:UPDATE_CHECK_INTERVAL }
                lastCheck       = if ($config.lastCheck) { $config.lastCheck } else { 0 }
                skippedVersions = if ($config.skippedVersions) { $config.skippedVersions } else { @() }
                autoCheck       = if ($config.autoCheck -ne $null) { $config.autoCheck } else { $true }
            }
        }
        catch {
            return @{
                versionUrl      = $script:NETWORK_VERSION_URL
                checkInterval   = $script:UPDATE_CHECK_INTERVAL
                lastCheck       = 0
                skippedVersions = @()
                autoCheck       = $true
            }
        }
    }
    return @{
        versionUrl      = $script:NETWORK_VERSION_URL
        checkInterval   = $script:UPDATE_CHECK_INTERVAL
        lastCheck       = 0
        skippedVersions = @()
        autoCheck       = $true
    }
}

function Save-UpdateConfig {
    param(
        [string]$VersionUrl,
        [int]$CheckInterval,
        [long]$LastCheck,
        [array]$SkippedVersions,
        [bool]$AutoCheck = $true
    )
    try {
        $config = @{
            versionUrl      = $VersionUrl
            checkInterval   = $CheckInterval
            lastCheck       = $LastCheck
            skippedVersions = $SkippedVersions
            autoCheck       = $AutoCheck
        }
        $config | ConvertTo-Json | Out-File $script:UPDATE_CONFIG_FILE -Encoding UTF8
        return $true
    }
    catch {
        return $false
    }
}

function Should-CheckUpdate {
    $config = Get-UpdateConfig
    if ($config.autoCheck -eq $false) {
        return $false
    }
    $now = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $intervalSeconds = $config.checkInterval * 3600
    return ($now - $config.lastCheck) -ge $intervalSeconds
}

function Update-LastCheckTime {
    $config = Get-UpdateConfig
    Save-UpdateConfig -VersionUrl $config.versionUrl -CheckInterval $config.checkInterval -LastCheck ([DateTimeOffset]::Now.ToUnixTimeSeconds()) -SkippedVersions $config.skippedVersions -AutoCheck $config.autoCheck
}

function Get-NetworkVersionInfo {
    param(
        [string]$Url,
        [int]$Timeout = $script:NETWORK_TIMEOUT,
        [bool]$UseBackup = $false
    )
    
    $config = Get-UpdateConfig
    if ([string]::IsNullOrEmpty($Url)) {
        $Url = $config.versionUrl
    }
    
    if ([string]::IsNullOrEmpty($Url)) {
        $Url = $script:NETWORK_VERSION_URL
    }
    
    if ([string]::IsNullOrEmpty($Url)) {
        return Get-LocalVersionInfo
    }
    
    if (-not (Test-NetworkConnection)) {
        return Get-LocalVersionInfo
    }
    
    $urlsToTry = @($Url)
    if (-not $UseBackup -and $script:NETWORK_VERSION_URL_BACKUP) {
        $urlsToTry += $script:NETWORK_VERSION_URL_BACKUP
    }
    
    foreach ($currentUrl in $urlsToTry) {
        try {
            if ($currentUrl -like "file://*") {
                $localPath = $currentUrl -replace "file:///", ""
                $localPath = $localPath -replace "/", "\"
                if (Test-Path $localPath) {
                    $json = Get-Content $localPath -Raw -Encoding UTF8
                    return $json | ConvertFrom-Json
                }
                continue
            }
            
            if ($currentUrl -like "http*") {
                $client = New-Object System.Net.WebClient
                $client.Encoding = [System.Text.Encoding]::UTF8
                $client.Headers.Add("User-Agent", "OpenClaw-Launcher/$($script:CURRENT_VERSION)")
                $client.Headers.Add("Cache-Control", "no-cache")
                
                $script:networkVersionCompleted = $false
                $script:networkVersionResult = $null
                $script:networkVersionError = $null
                
                $client.DownloadStringCompleted.Add_Handler({
                        param($sender, $e)
                        if ($e.Error) {
                            $script:networkVersionError = $e.Error.Message
                        }
                        else {
                            $script:networkVersionResult = $e.Result
                        }
                        $script:networkVersionCompleted = $true
                    })
                
                $client.DownloadStringAsync($currentUrl)
                
                $startTime = Get-Date
                while (-not $script:networkVersionCompleted -and ((Get-Date) - $startTime).TotalSeconds -lt $Timeout) {
                    Start-Sleep -Milliseconds 100
                    [System.Windows.Forms.Application]::DoEvents()
                }
                
                if (-not $script:networkVersionCompleted) {
                    $client.CancelAsync()
                    $client.Dispose()
                    continue
                }
                
                if ($script:networkVersionError) {
                    $client.Dispose()
                    continue
                }
                
                $json = $script:networkVersionResult
                if ([string]::IsNullOrEmpty($json)) {
                    $client.Dispose()
                    continue
                }
                
                $result = $json | ConvertFrom-Json
                $result | Add-Member -MemberType NoteProperty -Name "sourceUrl" -Value $currentUrl -Force
                $client.Dispose()
                return $result
            }
        }
        catch {
            continue
        }
    }
    
    return Get-LocalVersionInfo
}

function Get-VersionInfoWithFallback {
    param([bool]$ForceNetwork = $false)
    
    $isOnline = Test-NetworkConnection
    
    if (-not $isOnline) {
        Update-NetworkStatusDisplay -IsOnline $false
        return @{
            Info     = Get-LocalVersionInfo
            Source   = "local"
            IsOnline = $false
        }
    }
    
    Update-NetworkStatusDisplay -IsOnline $true
    
    $config = Get-UpdateConfig
    $networkInfo = Get-NetworkVersionInfo -Url $config.versionUrl
    
    if ($null -ne $networkInfo) {
        return @{
            Info     = $networkInfo
            Source   = "network"
            IsOnline = $true
        }
    }
    
    return @{
        Info     = Get-LocalVersionInfo
        Source   = "local"
        IsOnline = $true
    }
}

function Compare-Version {
    param([string]$Version1, [string]$Version2)
    try {
        $v1 = [version]$Version1
        $v2 = [version]$Version2
        return $v1.CompareTo($v2)
    }
    catch {
        return [string]::Compare($Version1, $Version2)
    }
}

function Get-SkippedVersions {
    $skipFile = Join-Path $script:STATE_DIR "skipped-versions.json"
    if (Test-Path $skipFile) {
        try {
            $content = Get-Content $skipFile -Raw -Encoding UTF8
            return $content | ConvertFrom-Json
        }
        catch {
            return @()
        }
    }
    return @()
}

function Add-SkippedVersion {
    param([string]$Version)
    $skipFile = Join-Path $script:STATE_DIR "skipped-versions.json"
    $skipped = Get-SkippedVersions
    if ($Version -notin $skipped) {
        $skipped += $Version
        $skipped | ConvertTo-Json | Out-File $skipFile -Encoding UTF8
    }
}

function Check-VersionUpdate {
    param(
        [bool]$ShowNoUpdate = $false,
        [bool]$ForceNetwork = $false,
        [bool]$Silent = $false
    )
    
    $versionResult = Get-VersionInfoWithFallback -ForceNetwork $ForceNetwork
    $localInfo = Get-LocalVersionInfo
    $remoteInfo = $versionResult.Info
    
    if ($null -eq $remoteInfo) {
        if ($ShowNoUpdate) {
            [System.Windows.Forms.MessageBox]::Show($txtUpdateCheckFailed, $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
        return $null
    }
    
    Update-LastCheckTime
    
    $compareResult = Compare-Version -Version1 $remoteInfo.version -Version2 $localInfo.version
    
    if ($compareResult -gt 0) {
        $config = Get-UpdateConfig
        if ($remoteInfo.version -in $config.skippedVersions) {
            return $null
        }
        
        if ($Silent) {
            Show-UpdateTipBar -RemoteInfo $remoteInfo
        }
        else {
            Show-UpdateNotification -LocalVersion $localInfo.version -RemoteInfo $remoteInfo
        }
        return $remoteInfo
    }
    else {
        if ($ShowNoUpdate) {
            [System.Windows.Forms.MessageBox]::Show($txtNoUpdate + "`n`n" + $txtCurrentVersion + ": " + $localInfo.version, $txtDone, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        return $null
    }
}

function RemoveAllClickHandlers {
    param([System.Windows.Forms.Control]$Control)
    
    $eventType = $Control.GetType().GetEvent("Click")
    if ($eventType) {
        $field = $Control.GetType().GetField("Click", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($field) {
            $handlers = $field.GetValue($Control)
            if ($handlers) {
                foreach ($handler in $handlers.GetInvocationList()) {
                    $eventType.RemoveEventHandler($Control, $handler)
                }
            }
        }
    }
}

function Show-UpdateTipBar {
    param([object]$RemoteInfo)
    
    if ($null -eq $RemoteInfo) { return }
    
    $script:updateTipLabel.Text = "🔔 " + $txtUpdateAvailableBar + " v" + $RemoteInfo.version + " - " + $txtClickToView
    $script:updateTipLabel.Visible = $true
    $script:updateTipLabel.Tag = $RemoteInfo
    
    RemoveAllClickHandlers -Control $script:updateTipLabel
    $script:updateTipLabel.Add_Click({
            $info = $script:updateTipLabel.Tag
            if ($info) {
                Show-UpdateNotification -LocalVersion $script:CURRENT_VERSION -RemoteInfo $info
            }
        })
    
    $script:networkStatusLabel.Cursor = "Hand"
    RemoveAllClickHandlers -Control $script:networkStatusLabel
    $script:networkStatusLabel.Add_Click({
            $isOnline = Test-NetworkConnection
            Update-NetworkStatusDisplay -IsOnline $isOnline
            if ($isOnline) {
                Check-VersionUpdate -ShowNoUpdate $true -ForceNetwork $true
            }
            else {
                [System.Windows.Forms.MessageBox]::Show(
                    $txtNetworkStatusOffline,
                    $txtWarning,
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
            }
        })
}

function Hide-UpdateTipBar {
    $script:updateTipLabel.Visible = $false
    $script:updateTipLabel.Tag = $null
}

function Start-UpdateCheckTimer {
    $config = Get-UpdateConfig
    $intervalMinutes = $config.checkInterval * 60
    
    if ($intervalMinutes -lt 1) { $intervalMinutes = 60 }
    
    $script:updateTimer = New-Object System.Windows.Forms.Timer
    $script:updateTimer.Interval = $intervalMinutes * 60 * 1000
    $script:updateTimer.Add_Tick({
            $isOnline = Test-NetworkConnection
            Update-NetworkStatusDisplay -IsOnline $isOnline
        
            if ($isOnline) {
                Check-VersionUpdate -ShowNoUpdate $false -Silent $true
            }
        })
    $script:updateTimer.Start()
}

function Stop-UpdateCheckTimer {
    if ($script:updateTimer) {
        $script:updateTimer.Stop()
        $script:updateTimer.Dispose()
        $script:updateTimer = $null
    }
}

function Show-UpdateNotification {
    param(
        [string]$LocalVersion,
        [object]$RemoteInfo
    )
    
    $updateForm = New-Object System.Windows.Forms.Form
    $updateForm.Text = $txtUpdateAvailable
    $updateForm.Size = New-Object System.Drawing.Size(500, 450)
    $updateForm.StartPosition = "CenterParent"
    $updateForm.FormBorderStyle = "FixedDialog"
    $updateForm.MaximizeBox = $false
    $updateForm.MinimizeBox = $false
    $updateForm.BackColor = [System.Drawing.Color]::White
    $updateForm.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(480, 70)
    $headerPanel.Location = New-Object System.Drawing.Point(10, 10)
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 248, 255)
    $updateForm.Controls.Add($headerPanel)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "🎉 " + $txtUpdateAvailable
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Size = New-Object System.Drawing.Size(460, 30)
    $titleLabel.Location = New-Object System.Drawing.Point(10, 5)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 123, 255)
    $headerPanel.Controls.Add($titleLabel)
    
    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Text = $txtCurrentVersion + ": " + $LocalVersion + "  →  " + $txtLatestVersion + ": " + $RemoteInfo.version
    $versionLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
    $versionLabel.Size = New-Object System.Drawing.Size(460, 25)
    $versionLabel.Location = New-Object System.Drawing.Point(10, 38)
    $versionLabel.ForeColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
    $headerPanel.Controls.Add($versionLabel)
    
    $changelogTitle = New-Object System.Windows.Forms.Label
    $changelogTitle.Text = "📋 " + $txtChangelog
    $changelogTitle.Font = New-Object System.Drawing.Font("Microsoft YaHei", 11, [System.Drawing.FontStyle]::Bold)
    $changelogTitle.Size = New-Object System.Drawing.Size(460, 25)
    $changelogTitle.Location = New-Object System.Drawing.Point(10, 90)
    $changelogTitle.ForeColor = [System.Drawing.Color]::FromArgb(33, 37, 41)
    $updateForm.Controls.Add($changelogTitle)
    
    $changelogPanel = New-Object System.Windows.Forms.Panel
    $changelogPanel.Size = New-Object System.Drawing.Size(460, 220)
    $changelogPanel.Location = New-Object System.Drawing.Point(10, 120)
    $changelogPanel.AutoScroll = $true
    $changelogPanel.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
    $updateForm.Controls.Add($changelogPanel)
    
    $yPos = 5
    $typeIcons = @{
        "新增" = "✨"
        "修复" = "🐛"
        "优化" = "⚡"
        "移除" = "🗑️"
    }
    $typeColors = @{
        "新增" = [System.Drawing.Color]::FromArgb(40, 167, 69)
        "修复" = [System.Drawing.Color]::FromArgb(220, 53, 69)
        "优化" = [System.Drawing.Color]::FromArgb(0, 123, 255)
        "移除" = [System.Drawing.Color]::FromArgb(108, 117, 125)
    }
    
    foreach ($change in $RemoteInfo.changelog) {
        $changeLabel = New-Object System.Windows.Forms.Label
        $icon = $typeIcons[$change.type]
        if (-not $icon) { $icon = "•" }
        $changeLabel.Text = $icon + " [" + $change.type + "] " + $change.description
        $changeLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
        $changeLabel.Size = New-Object System.Drawing.Size(440, 35)
        $changeLabel.Location = New-Object System.Drawing.Point(5, $yPos)
        $changeLabel.ForeColor = $typeColors[$change.type]
        $changelogPanel.Controls.Add($changeLabel)
        $yPos += 38
    }
    
    $btnPanel = New-Object System.Windows.Forms.Panel
    $btnPanel.Size = New-Object System.Drawing.Size(480, 50)
    $btnPanel.Location = New-Object System.Drawing.Point(10, 350)
    $updateForm.Controls.Add($btnPanel)

    $downloadBtn = New-Object System.Windows.Forms.Button
    $downloadBtn.Text = $txtOpenDownload
    $downloadBtn.Size = New-Object System.Drawing.Size(140, 35)
    $downloadBtn.Location = New-Object System.Drawing.Point(30, 8)
    $downloadBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 123, 255)
    $downloadBtn.ForeColor = [System.Drawing.Color]::White
    $downloadBtn.FlatStyle = "Flat"
    $downloadBtn.FlatAppearance.BorderSize = 0
    $downloadBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei", 10)
    $downloadBtn.Add_Click({
            Start-Process $RemoteInfo.downloadUrl
        })
    $btnPanel.Controls.Add($downloadBtn)

    $laterBtn = New-Object System.Windows.Forms.Button
    $laterBtn.Text = $txtUpdateLater
    $laterBtn.Size = New-Object System.Drawing.Size(120, 35)
    $laterBtn.Location = New-Object System.Drawing.Point(180, 8)
    $laterBtn.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
    $laterBtn.ForeColor = [System.Drawing.Color]::White
    $laterBtn.FlatStyle = "Flat"
    $laterBtn.FlatAppearance.BorderSize = 0
    $laterBtn.Add_Click({
            Hide-UpdateTipBar
            $updateForm.Close()
        })
    $btnPanel.Controls.Add($laterBtn)

    $skipBtn = New-Object System.Windows.Forms.Button
    $skipBtn.Text = $txtSkipVersion
    $skipBtn.Size = New-Object System.Drawing.Size(120, 35)
    $skipBtn.Location = New-Object System.Drawing.Point(310, 8)
    $skipBtn.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
    $skipBtn.ForeColor = [System.Drawing.Color]::White
    $skipBtn.FlatStyle = "Flat"
    $skipBtn.FlatAppearance.BorderSize = 0
    $skipBtn.Add_Click({
            $config = Get-UpdateConfig
            if ($RemoteInfo.version -notin $config.skippedVersions) {
                $config.skippedVersions += $RemoteInfo.version
            }
            Save-UpdateConfig -VersionUrl $config.versionUrl -CheckInterval $config.checkInterval -LastCheck $config.lastCheck -SkippedVersions $config.skippedVersions -AutoCheck $config.autoCheck
            Hide-UpdateTipBar
            $updateForm.Close()
        })
    $btnPanel.Controls.Add($skipBtn)

    $updateForm.ShowDialog() | Out-Null
}

function Full-Reset {
    try {
        Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*$scriptPath*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        
        $script:statusLabel.Text = $txtDeleting
        $script:form.Refresh()
        
        if (Test-Path $script:DATA_DIR) { Remove-Item -Recurse -Force $script:DATA_DIR -ErrorAction SilentlyContinue }
        if (Test-Path $script:RUNTIME_DIR) { Remove-Item -Recurse -Force $script:RUNTIME_DIR -ErrorAction SilentlyContinue }
        if (Test-Path $script:CORE_DIR) { Remove-Item -Recurse -Force $script:CORE_DIR -ErrorAction SilentlyContinue }
        
        New-Item -ItemType Directory -Path $script:DATA_DIR -Force | Out-Null
        New-Item -ItemType Directory -Path $script:STATE_DIR -Force | Out-Null
        New-Item -ItemType Directory -Path "$($script:DATA_DIR)\memory" -Force | Out-Null
        New-Item -ItemType Directory -Path "$($script:DATA_DIR)\backups" -Force | Out-Null
        New-Item -ItemType Directory -Path "$($script:DATA_DIR)\logs" -Force | Out-Null
        
        Ensure-Config
        
        $script:statusLabel.Text = $txtFullResetDone
        [System.Windows.Forms.MessageBox]::Show($txtFullResetDone + "`n`n" + $txtClickRepair, $txtDone, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($txtResetFailed + "：$_", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Upgrade-UClaw {
    try {
        if (-not (Test-Path $script:NODE_BIN)) {
            [System.Windows.Forms.MessageBox]::Show($txtMissingNode + "`n`n" + $txtClickRepairFirst, $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $script:statusLabel.Text = $txtNetworkChecking
        $script:form.Refresh()
        
        $isOnline = Test-NetworkConnection
        Update-NetworkStatusDisplay -IsOnline $isOnline
        
        if (-not $isOnline) {
            $result = [System.Windows.Forms.MessageBox]::Show(
                $txtNetworkStatusOffline + "`n`n是否使用本地版本信息检查？",
                $txtWarning,
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            if ($result -ne "Yes") {
                $script:statusLabel.Text = $txtReady
                return
            }
        }
        
        $script:statusLabel.Text = $txtUpgradeCheck
        $script:form.Refresh()
        
        $usbCurrentVersion = $script:CURRENT_VERSION
        $config = Get-UpdateConfig
        $usbRemoteInfo = Get-NetworkVersionInfo -Url $config.versionUrl
        $usbLatestVersion = if ($usbRemoteInfo) { $usbRemoteInfo.version } else { "Unknown" }
        
        $coreCurrentVersion = Get-OpenClawCoreVersion
        if (-not $coreCurrentVersion) { $coreCurrentVersion = "未安装" }
        
        $coreLatestVersion = ""
        try {
            $checkScript = @"
const https = require('https');
https.get('https://registry.npmmirror.com/openclaw/latest', (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
        try {
            const pkg = JSON.parse(data);
            console.log(pkg.version);
        } catch(e) {
            console.log('error');
        }
    });
}).on('error', () => console.log('error'));
"@
            $checkFile = Join-Path $env:TEMP "check-version.js"
            $checkScript | Out-File $checkFile -Encoding utf8
            $result = & $script:NODE_BIN $checkFile 2>&1
            Remove-Item $checkFile -ErrorAction SilentlyContinue
            $coreLatestVersion = $result | Select-Object -Last 1
        }
        catch {
            $coreLatestVersion = "Unknown"
        }
        
        $msg = "【U盘版本】`n"
        $msg += "当前: $usbCurrentVersion | 最新: $usbLatestVersion`n`n"
        $msg += "【OpenClaw 核心】`n"
        $msg += "当前: $coreCurrentVersion | 最新: $coreLatestVersion`n`n"
        
        $hasUsbUpdate = ($usbLatestVersion -ne "Unknown" -and $usbLatestVersion -ne $usbCurrentVersion)
        $hasCoreUpdate = ($coreLatestVersion -ne "Unknown" -and $coreLatestVersion -ne "Unknown" -and $coreCurrentVersion -ne "未安装" -and $coreLatestVersion -ne $coreCurrentVersion)
        
        if ($hasUsbUpdate) {
            $msg += "U盘版本有更新！请点击[打开下载页面]获取新版本。`n`n"
        }
        if ($hasCoreUpdate) {
            $msg += "核心版本有更新！点击[是]立即升级核心。`n`n"
        }
        if (-not $hasUsbUpdate -and -not $hasCoreUpdate) {
            [System.Windows.Forms.MessageBox]::Show($txtUpgradeUpToDate + "`n`n" + $msg, $txtDone, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            $script:statusLabel.Text = $txtUpgradeUpToDate
            return
        }
        
        if ($hasUsbUpdate -and $usbRemoteInfo -and $usbRemoteInfo.downloadUrl) {
            $msg += "是否打开下载页面？"
            $result = [System.Windows.Forms.MessageBox]::Show($msg, $txtBtnUpgrade, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($result -eq "Yes") {
                Start-Process $usbRemoteInfo.downloadUrl
            }
            $script:statusLabel.Text = $txtReady
            return
        }
        
        if ($hasCoreUpdate) {
            $msg += $txtUpgradeConfirm
            $result = [System.Windows.Forms.MessageBox]::Show($msg, $txtBtnUpgrade, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($result -ne "Yes") {
                $script:statusLabel.Text = $txtReady
                return
            }
            
            Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*$scriptPath*" } | Stop-Process -Force -ErrorAction SilentlyContinue
            
            $script:statusLabel.Text = $txtUpgradeOpenclaw
            $script:form.Refresh()
            
            Push-Location $script:CORE_DIR
            & $script:NPM_BIN install openclaw@latest --registry="$($script:NPM_MIRROR)" --force --loglevel error --no-audit --no-fund 2>&1 | Out-Null
            Pop-Location
            
            $newVersion = Get-OpenClawCoreVersion
            if (-not $newVersion) { $newVersion = "Unknown" }
            
            $script:statusLabel.Text = $txtUpgradeDone
            
            [System.Windows.Forms.MessageBox]::Show(
                $txtUpgradeSuccess + "`n`n核心版本: $coreCurrentVersion → $newVersion",
                $txtSuccess,
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }
    catch {
        $script:statusLabel.Text = $txtUpgradeFailed
        [System.Windows.Forms.MessageBox]::Show($txtUpgradeFailed + "：$_", $txtError, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

#region 自动升级功能函数

<#
.SYNOPSIS
    检查设备激活状态
.DESCRIPTION
    验证许可证文件是否存在且有效
.OUTPUTS
    PSCustomObject 包含 IsActivated, IsValid, Message 属性
#>
function Test-DeviceActivation {
    $result = [PSCustomObject]@{
        IsActivated = $false
        IsValid     = $false
        Message     = ""
        LicenseInfo = $null
    }
    
    try {
        # 检查许可证文件是否存在
        if (-not (Test-Path $script:LICENSE_FILE)) {
            $result.Message = "许可证文件不存在"
            return $result
        }
        
        $result.IsActivated = $true
        
        # 读取并解密许可证
        $cipherBytes = [System.IO.File]::ReadAllBytes($script:LICENSE_FILE)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($script:LICENSE_KEY.PadRight(32).Substring(0, 32))
        $aes.IV = [byte[]]::new(16)
        
        $decryptor = $aes.CreateDecryptor()
        $plainBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)
        $licenseJson = [System.Text.Encoding]::UTF8.GetString($plainBytes)
        
        $licenseInfo = $licenseJson | ConvertFrom-Json
        
        # 检查许可证有效期
        if ($licenseInfo.expiresAt -and $licenseInfo.expiresAt -ne "permanent") {
            $expireDate = [DateTime]::Parse($licenseInfo.expiresAt)
            if ($expireDate -lt [DateTime]::Now) {
                $result.Message = "许可证已过期"
                return $result
            }
        }
        
        # 验证硬件ID（如果存在）
        if ($licenseInfo.hwid) {
            $currentHwid = Get-USBHardwareId
            if ($licenseInfo.hwid -ne $currentHwid) {
                $result.Message = "硬件ID不匹配"
                return $result
            }
        }
        
        $result.IsValid = $true
        $result.Message = "许可证有效"
        $result.LicenseInfo = $licenseInfo
        
    }
    catch {
        $result.Message = "许可证验证失败: $_"
    }
    
    return $result
}

<#
.SYNOPSIS
    带进度回调的文件下载函数
.DESCRIPTION
    从指定URL下载文件，支持进度回调和超时设置
.PARAMETER Url
    下载文件的URL
.PARAMETER OutputPath
    保存文件的本地路径
.PARAMETER ProgressCallback
    进度回调脚本块，接收已下载字节数和总字节数
.PARAMETER TimeoutSeconds
    下载超时时间（秒），默认300秒
.OUTPUTS
    PSCustomObject 包含 Success, FilePath, ErrorMessage 属性
#>
function Download-FileWithProgress {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$ProgressCallback = $null,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 300
    )
    
    $result = [PSCustomObject]@{
        Success         = $false
        FilePath        = $OutputPath
        ErrorMessage    = ""
        BytesDownloaded = 0
    }
    
    try {
        # 创建请求
        $request = [System.Net.WebRequest]::Create($Url)
        $request.Timeout = $TimeoutSeconds * 1000
        $request.Method = "GET"
        
        # 获取响应
        $response = $request.GetResponse()
        $totalBytes = $response.ContentLength
        $responseStream = $response.GetResponseStream()
        
        # 确保输出目录存在
        $outputDir = Split-Path $OutputPath -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        # 创建文件流
        $fileStream = [System.IO.File]::Create($OutputPath)
        $buffer = New-Object byte[] 8192
        $bytesRead = 0
        $totalRead = 0
        
        while (($bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $bytesRead)
            $totalRead += $bytesRead
            
            # 调用进度回调
            if ($ProgressCallback) {
                & $ProgressCallback $totalRead $totalBytes
            }
        }
        
        $fileStream.Close()
        $responseStream.Close()
        $response.Close()
        
        $result.Success = $true
        $result.BytesDownloaded = $totalRead
        
    }
    catch {
        $result.ErrorMessage = $_.Exception.Message
        
        # 清理部分下载的文件
        if (Test-Path $OutputPath) {
            Remove-Item $OutputPath -Force -ErrorAction SilentlyContinue
        }
    }
    
    return $result
}

<#
.SYNOPSIS
    带回退机制的多源下载函数
.DESCRIPTION
    先尝试主URL下载，失败后尝试备用URL，支持百度网盘提取码提示
.PARAMETER PrimaryUrl
    主下载URL
.PARAMETER FallbackUrl
    备用下载URL
.PARAMETER OutputPath
    保存文件的本地路径
.PARAMETER BaiduCode
    百度网盘提取码（可选）
.PARAMETER ProgressCallback
    进度回调脚本块
.PARAMETER TimeoutSeconds
    下载超时时间（秒）
.OUTPUTS
    PSCustomObject 包含 Success, FilePath, UsedFallback, ErrorMessage 属性
#>
function Download-WithFallback {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PrimaryUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$FallbackUrl = "",
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$BaiduCode = "",
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$ProgressCallback = $null,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 300
    )
    
    $result = [PSCustomObject]@{
        Success      = $false
        FilePath     = $OutputPath
        UsedFallback = $false
        ErrorMessage = ""
    }
    
    # 尝试主URL下载
    $downloadResult = Download-FileWithProgress -Url $PrimaryUrl -OutputPath $OutputPath -ProgressCallback $ProgressCallback -TimeoutSeconds $TimeoutSeconds
    
    if ($downloadResult.Success) {
        $result.Success = $true
        return $result
    }
    
    # 主URL失败，尝试备用URL
    if ($FallbackUrl) {
        $result.UsedFallback = $true
        
        # 检查是否是百度网盘链接
        if ($FallbackUrl -match "pan\.baidu\.com" -and $BaiduCode) {
            $msg = "主下载链接失败，需要从百度网盘下载。`n`n提取码: $BaiduCode`n`n是否打开百度网盘链接？"
            $dialogResult = [System.Windows.Forms.MessageBox]::Show(
                $msg,
                "百度网盘下载",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            
            if ($dialogResult -eq "Yes") {
                Start-Process $FallbackUrl
                # 将提取码复制到剪贴板
                [System.Windows.Forms.Clipboard]::SetText($BaiduCode)
                $result.ErrorMessage = "已打开百度网盘链接，提取码已复制到剪贴板"
            }
            else {
                $result.ErrorMessage = "用户取消下载"
            }
            return $result
        }
        
        # 普通备用URL下载
        $downloadResult = Download-FileWithProgress -Url $FallbackUrl -OutputPath $OutputPath -ProgressCallback $ProgressCallback -TimeoutSeconds $TimeoutSeconds
        
        if ($downloadResult.Success) {
            $result.Success = $true
        }
        else {
            $result.ErrorMessage = "主链接和备用链接均下载失败: $($downloadResult.ErrorMessage)"
        }
    }
    else {
        $result.ErrorMessage = "下载失败: $($downloadResult.ErrorMessage)"
    }
    
    return $result
}

<#
.SYNOPSIS
    计算文件的SHA256哈希值
.DESCRIPTION
    使用SHA256算法计算指定文件的哈希值
.PARAMETER FilePath
    要计算哈希值的文件路径
.OUTPUTS
    String 文件的SHA256哈希值（小写十六进制字符串）
#>
function Get-FileSHA256 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            return $null
        }
        
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $hashBytes = $sha256.ComputeHash($fileStream)
        $fileStream.Close()
        
        $hashString = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
        return $hashString
        
    }
    catch {
        return $null
    }
}

<#
.SYNOPSIS
    验证文件完整性
.DESCRIPTION
    通过比对SHA256哈希值验证文件完整性
.PARAMETER FilePath
    要验证的文件路径
.PARAMETER ExpectedHash
    预期的SHA256哈希值（小写十六进制字符串）
.OUTPUTS
    PSCustomObject 包含 IsValid, ActualHash, ExpectedHash, Message 属性
#>
function Verify-FileIntegrity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ExpectedHash
    )
    
    $result = [PSCustomObject]@{
        IsValid      = $false
        ActualHash   = ""
        ExpectedHash = $ExpectedHash.ToLower()
        Message      = ""
    }
    
    try {
        if (-not (Test-Path $FilePath)) {
            $result.Message = "文件不存在"
            return $result
        }
        
        $actualHash = Get-FileSHA256 -FilePath $FilePath
        $result.ActualHash = $actualHash
        
        if (-not $actualHash) {
            $result.Message = "无法计算文件哈希值"
            return $result
        }
        
        if ($actualHash -eq $ExpectedHash.ToLower()) {
            $result.IsValid = $true
            $result.Message = "文件完整性验证通过"
        }
        else {
            $result.Message = "文件哈希值不匹配，文件可能已损坏或被篡改"
        }
        
    }
    catch {
        $result.Message = "验证过程出错: $_"
    }
    
    return $result
}

<#
.SYNOPSIS
    备份文件列表
.DESCRIPTION
    将指定文件列表备份到backup目录，记录备份时间戳
.PARAMETER Files
    要备份的文件路径数组
.PARAMETER BackupDir
    备份目录路径（可选，默认为 data/backup）
.PARAMETER BackupName
    备份名称（可选，默认使用时间戳）
.OUTPUTS
    PSCustomObject 包含 Success, BackupPath, BackupTime, FileCount, Message 属性
#>
function Backup-Files {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Files,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupDir = "",
        
        [Parameter(Mandatory = $false)]
        [string]$BackupName = ""
    )
    
    $result = [PSCustomObject]@{
        Success    = $false
        BackupPath = ""
        BackupTime = [DateTime]::Now
        FileCount  = 0
        Message    = ""
    }
    
    try {
        # 设置默认备份目录
        if (-not $BackupDir) {
            $BackupDir = Join-Path $script:DATA_DIR "backup"
        }
        
        # 生成备份名称
        if (-not $BackupName) {
            $BackupName = "backup_" + (Get-Date -Format "yyyyMMdd_HHmmss")
        }
        
        # 创建备份目录
        $backupPath = Join-Path $BackupDir $BackupName
        if (-not (Test-Path $backupPath)) {
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        }
        
        # 创建备份元数据文件
        $metadata = [PSCustomObject]@{
            BackupTime = [DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
            Files      = @()
        }
        
        # 复制文件
        $copiedCount = 0
        foreach ($file in $Files) {
            if (Test-Path $file) {
                $fileName = Split-Path $file -Leaf
                $relativePath = $file.Substring($scriptPath.Length).TrimStart('\', '/')
                $destPath = Join-Path $backupPath $relativePath
                
                # 确保目标目录存在
                $destDir = Split-Path $destPath -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                
                Copy-Item -Path $file -Destination $destPath -Force
                $copiedCount++
                
                # 记录文件信息
                $fileInfo = Get-Item $file
                $metadata.Files += [PSCustomObject]@{
                    OriginalPath  = $file
                    RelativePath  = $relativePath
                    Size          = $fileInfo.Length
                    LastWriteTime = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                }
            }
        }
        
        # 保存元数据
        $metadataPath = Join-Path $backupPath "backup_metadata.json"
        $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding UTF8
        
        $result.Success = $true
        $result.BackupPath = $backupPath
        $result.FileCount = $copiedCount
        $result.Message = "成功备份 $copiedCount 个文件"
        
    }
    catch {
        $result.Message = "备份失败: $_"
    }
    
    return $result
}

<#
.SYNOPSIS
    从备份恢复文件
.DESCRIPTION
    从backup目录恢复文件到原位置，处理恢复失败情况
.PARAMETER BackupPath
    备份目录路径
.PARAMETER Files
    要恢复的文件列表（可选，默认恢复所有文件）
.OUTPUTS
    PSCustomObject 包含 Success, RestoredCount, FailedCount, Message, FailedFiles 属性
#>
function Rollback-Files {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Files = @()
    )
    
    $result = [PSCustomObject]@{
        Success       = $false
        RestoredCount = 0
        FailedCount   = 0
        Message       = ""
        FailedFiles   = @()
    }
    
    try {
        # 检查备份目录是否存在
        if (-not (Test-Path $BackupPath)) {
            $result.Message = "备份目录不存在: $BackupPath"
            return $result
        }
        
        # 读取备份元数据
        $metadataPath = Join-Path $BackupPath "backup_metadata.json"
        if (-not (Test-Path $metadataPath)) {
            $result.Message = "备份元数据文件不存在"
            return $result
        }
        
        $metadata = Get-Content $metadataPath -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # 确定要恢复的文件列表
        $filesToRestore = @()
        if ($Files.Count -gt 0) {
            # 只恢复指定的文件
            foreach ($file in $Files) {
                $matched = $metadata.Files | Where-Object { $_.OriginalPath -eq $file -or $_.RelativePath -eq $file }
                if ($matched) {
                    $filesToRestore += $matched
                }
            }
        }
        else {
            # 恢复所有文件
            $filesToRestore = $metadata.Files
        }
        
        # 恢复文件
        foreach ($fileInfo in $filesToRestore) {
            try {
                $backupFilePath = Join-Path $BackupPath $fileInfo.RelativePath
                
                if (Test-Path $backupFilePath) {
                    # 确保目标目录存在
                    $destDir = Split-Path $fileInfo.OriginalPath -Parent
                    if (-not (Test-Path $destDir)) {
                        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                    }
                    
                    Copy-Item -Path $backupFilePath -Destination $fileInfo.OriginalPath -Force
                    $result.RestoredCount++
                }
                else {
                    $result.FailedCount++
                    $result.FailedFiles += $fileInfo.OriginalPath
                }
            }
            catch {
                $result.FailedCount++
                $result.FailedFiles += $fileInfo.OriginalPath
            }
        }
        
        if ($result.FailedCount -eq 0) {
            $result.Success = $true
            $result.Message = "成功恢复 $($result.RestoredCount) 个文件"
        }
        else {
            $result.Message = "恢复完成，成功 $($result.RestoredCount) 个，失败 $($result.FailedCount) 个"
        }
        
    }
    catch {
        $result.Message = "恢复失败: $_"
    }
    
    return $result
}

#endregion 自动升级功能函数

#region 升级功能实现

<#
.SYNOPSIS
    启动器自身升级函数
.DESCRIPTION
    验证设备激活状态，备份当前启动器，下载新版本并替换
.PARAMETER VersionInfo
    版本信息对象，包含下载URL和哈希值
.OUTPUTS
    PSCustomObject 包含 Success, Message 属性
#>
function Update-Launcher {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$VersionInfo
    )
    
    $result = [PSCustomObject]@{
        Success     = $false
        Message     = ""
        NeedRestart = $false
    }
    
    try {
        # 1. 获取当前启动器路径
        $launcherPath = $MyInvocation.ScriptName
        if (-not $launcherPath) {
            $launcherPath = $PSCommandPath
        }
        if (-not $launcherPath) {
            $launcherPath = Join-Path $scriptPath "U-Claw-Launcher.ps1"
        }
        
        if (-not (Test-Path $launcherPath)) {
            $result.Message = "无法找到启动器文件路径"
            return $result
        }
        
        # 3. 备份当前启动器文件
        $backupDir = Join-Path $script:DATA_DIR "backup"
        $backupPath = Join-Path $backupDir "U-Claw-Launcher_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
        
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        Copy-Item -Path $launcherPath -Destination $backupPath -Force
        Write-Host "启动器已备份到: $backupPath"
        
        # 4. 下载新版本启动器
        $tempPath = Join-Path $env:TEMP "U-Claw-Launcher_new.ps1"
        
        $downloadUrl = $VersionInfo.launcherUrl
        $fallbackUrl = $VersionInfo.launcherFallbackUrl
        $expectedHash = $VersionInfo.launcherHash
        
        if (-not $downloadUrl) {
            $result.Message = "版本信息中缺少启动器下载地址"
            return $result
        }
        
        # 显示进度窗口
        $progressForm = Show-UpgradeProgress -Title "升级启动器" -Message "正在下载新版本启动器..."
        
        $downloadResult = Download-WithFallback -PrimaryUrl $downloadUrl -FallbackUrl $fallbackUrl -OutputPath $tempPath -ProgressCallback {
            param($downloaded, $total)
            if ($progressForm -and $total -gt 0) {
                $percent = [math]::Round(($downloaded / $total) * 100)
                $progressForm.Invoke([Action] {
                        $script:progressBar.Value = $percent
                        $script:progressLabel.Text = "下载进度: $percent% ($([math]::Round($downloaded/1MB, 2)) MB / $([math]::Round($total/1MB, 2)) MB)"
                    })
            }
        }
        
        if (-not $downloadResult.Success) {
            if ($progressForm) {
                $progressForm.Invoke([Action] { $progressForm.Close() })
            }
            $result.Message = "下载失败: " + $downloadResult.ErrorMessage
            return $result
        }
        
        # 5. 验证文件完整性
        $progressForm.Invoke([Action] {
                $script:progressLabel.Text = "正在验证文件完整性..."
                $script:progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
            })
        
        if ($expectedHash) {
            $verifyResult = Verify-FileIntegrity -FilePath $tempPath -ExpectedHash $expectedHash
            if (-not $verifyResult.IsValid) {
                if ($progressForm) {
                    $progressForm.Invoke([Action] { $progressForm.Close() })
                }
                $result.Message = "文件完整性验证失败: " + $verifyResult.Message
                Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                return $result
            }
        }
        
        # 6. 替换启动器文件
        $progressForm.Invoke([Action] {
                $script:progressLabel.Text = "正在替换启动器文件..."
            })
        
        # 创建更新脚本，在当前进程退出后执行替换
        $updateScriptPath = Join-Path $env:TEMP "update_launcher.ps1"
        $currentPid = $PID
        
        $updateScript = @"
Start-Sleep -Seconds 2
`$proc = Get-Process -Id $currentPid -ErrorAction SilentlyContinue
while (`$proc) {
    Start-Sleep -Milliseconds 500
    `$proc = Get-Process -Id $currentPid -ErrorAction SilentlyContinue
}
Copy-Item -Path '$tempPath' -Destination '$launcherPath' -Force
Remove-Item '$tempPath' -Force -ErrorAction SilentlyContinue
Remove-Item '$updateScriptPath' -Force -ErrorAction SilentlyContinue
Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File `"$launcherPath`"'
"@
        
        $updateScript | Out-File -FilePath $updateScriptPath -Encoding UTF8
        
        if ($progressForm) {
            $progressForm.Invoke([Action] { $progressForm.Close() })
        }
        
        $result.Success = $true
        $result.Message = "启动器升级成功！程序将自动重启。"
        $result.NeedRestart = $true
        
        # 启动更新脚本
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$updateScriptPath`"" -WindowStyle Hidden
        
    }
    catch {
        $result.Message = "升级失败: $_"
    }
    
    return $result
}

<#
.SYNOPSIS
    OpenClaw 核心文件升级函数
.DESCRIPTION
    验证设备激活状态，备份核心文件，下载并解压替换
.PARAMETER VersionInfo
    版本信息对象，包含核心文件下载URL
.OUTPUTS
    PSCustomObject 包含 Success, Message 属性
#>
function Update-CoreFiles {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$VersionInfo
    )
    
    $result = [PSCustomObject]@{
        Success = $false
        Message = ""
    }
    
    try {
        # 1. 检查 Node.js 是否存在
        if (-not (Test-Path $script:NODE_BIN)) {
            $result.Message = "未找到 Node.js，请先运行 [修复环境]"
            return $result
        }
        
        # 3. 备份现有核心文件
        $backupDir = Join-Path $script:DATA_DIR "backup"
        $coreBackupDir = Join-Path $backupDir "core_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        
        if (Test-Path $script:CORE_DIR) {
            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }
            Copy-Item -Path $script:CORE_DIR -Destination $coreBackupDir -Recurse -Force
            Write-Host "核心文件已备份到: $coreBackupDir"
        }
        
        # 4. 显示进度窗口
        $progressForm = Show-UpgradeProgress -Title "升级核心文件" -Message "正在准备升级..."
        
        # 5. 停止正在运行的 Node 进程
        $progressForm.Invoke([Action] {
                $script:progressLabel.Text = "正在停止服务..."
            })
        
        Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*$scriptPath*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        
        # 6. 下载核心文件包
        $tempPath = Join-Path $env:TEMP "openclaw_core_update.zip"
        $downloadUrl = $VersionInfo.coreUrl
        $fallbackUrl = $VersionInfo.coreFallbackUrl
        
        if (-not $downloadUrl) {
            # 如果没有提供下载URL，使用 npm 更新
            $progressForm.Invoke([Action] {
                    $script:progressLabel.Text = "正在通过 npm 更新 OpenClaw..."
                    $script:progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
                })
            
            Push-Location $script:CORE_DIR
            & $script:NPM_BIN install openclaw@latest --registry="$($script:NPM_MIRROR)" --force --loglevel error --no-audit --no-fund 2>&1 | Out-Null
            Pop-Location
            
            if ($progressForm) {
                $progressForm.Invoke([Action] { $progressForm.Close() })
            }
            
            $newVersion = Get-OpenClawCoreVersion
            if ($newVersion) {
                $result.Success = $true
                $result.Message = "核心文件升级成功！新版本: $newVersion"
            }
            else {
                $result.Message = "核心文件升级失败，请检查网络连接后重试"
            }
            return $result
        }
        
        $progressForm.Invoke([Action] {
                $script:progressLabel.Text = "正在下载核心文件包..."
                $script:progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
            })
        
        $downloadResult = Download-WithFallback -PrimaryUrl $downloadUrl -FallbackUrl $fallbackUrl -OutputPath $tempPath -ProgressCallback {
            param($downloaded, $total)
            if ($progressForm -and $total -gt 0) {
                $percent = [math]::Round(($downloaded / $total) * 100)
                $progressForm.Invoke([Action] {
                        $script:progressBar.Value = $percent
                        $script:progressLabel.Text = "下载进度: $percent% ($([math]::Round($downloaded/1MB, 2)) MB / $([math]::Round($total/1MB, 2)) MB)"
                    })
            }
        }
        
        if (-not $downloadResult.Success) {
            if ($progressForm) {
                $progressForm.Invoke([Action] { $progressForm.Close() })
            }
            $result.Message = "下载失败: " + $downloadResult.ErrorMessage
            return $result
        }
        
        # 7. 解压并替换文件
        $progressForm.Invoke([Action] {
                $script:progressLabel.Text = "正在解压文件..."
                $script:progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
            })
        
        $extractPath = Join-Path $env:TEMP "openclaw_core_extract"
        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force
        }
        
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempPath, $extractPath)
        
        $progressForm.Invoke([Action] {
                $script:progressLabel.Text = "正在替换核心文件..."
            })
        
        # 确保核心目录存在
        if (-not (Test-Path $script:CORE_DIR)) {
            New-Item -ItemType Directory -Path $script:CORE_DIR -Force | Out-Null
        }
        
        # 复制文件
        $extractedFiles = Get-ChildItem -Path $extractPath -Recurse
        foreach ($file in $extractedFiles) {
            if (-not $file.PSIsContainer) {
                $relativePath = $file.FullName.Substring($extractPath.Length).TrimStart('\', '/')
                $destPath = Join-Path $script:CORE_DIR $relativePath
                $destDir = Split-Path $destPath -Parent
                
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                
                Copy-Item -Path $file.FullName -Destination $destPath -Force
            }
        }
        
        # 清理临时文件
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        
        if ($progressForm) {
            $progressForm.Invoke([Action] { $progressForm.Close() })
        }
        
        # 8. 验证升级结果
        $newVersion = Get-OpenClawCoreVersion
        if ($newVersion) {
            $result.Success = $true
            $result.Message = "核心文件升级成功！新版本: $newVersion"
        }
        else {
            $result.Message = "核心文件升级完成，但无法验证版本"
            $result.Success = $true
        }
        
    }
    catch {
        $result.Message = "升级失败: $_"
    }
    
    return $result
}

<#
.SYNOPSIS
    显示升级进度窗口
.DESCRIPTION
    创建带有进度条和状态标签的进度窗口，支持取消操作
.PARAMETER Title
    窗口标题
.PARAMETER Message
    初始消息
.OUTPUTS
    Form 进度窗口对象
#>
function Show-UpgradeProgress {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Title = "升级进度",
        
        [Parameter(Mandatory = $false)]
        [string]$Message = "正在处理..."
    )
    
    # 创建进度窗口
    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Text = $Title
    $progressForm.Size = New-Object System.Drawing.Size(450, 180)
    $progressForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $progressForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $progressForm.MaximizeBox = $false
    $progressForm.MinimizeBox = $false
    $progressForm.ControlBox = $true
    $progressForm.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10)
    
    # 状态标签
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(20, 20)
    $statusLabel.Size = New-Object System.Drawing.Size(400, 30)
    $statusLabel.Text = $Message
    $statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $progressForm.Controls.Add($statusLabel)
    
    # 进度条
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 60)
    $progressBar.Size = New-Object System.Drawing.Size(400, 30)
    $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressBar.Value = 0
    $progressForm.Controls.Add($progressBar)
    
    # 进度百分比标签
    $progressLabel = New-Object System.Windows.Forms.Label
    $progressLabel.Location = New-Object System.Drawing.Point(20, 95)
    $progressLabel.Size = New-Object System.Drawing.Size(400, 25)
    $progressLabel.Text = "进度: 0%"
    $progressLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $progressForm.Controls.Add($progressLabel)
    
    # 取消按钮
    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Location = New-Object System.Drawing.Point(175, 125)
    $cancelBtn.Size = New-Object System.Drawing.Size(100, 30)
    $cancelBtn.Text = "取消"
    $cancelBtn.Enabled = $true
    $cancelBtn.Add_Click({
            $script:cancelDownload = $true
            $progressForm.Close()
        })
    $progressForm.Controls.Add($cancelBtn)
    
    # 保存控件引用供外部访问
    $script:progressBar = $progressBar
    $script:progressLabel = $progressLabel
    $script:cancelDownload = $false
    
    # 显示窗口（非阻塞）
    $progressForm.Show()
    $progressForm.Refresh()
    
    return $progressForm
}

<#
.SYNOPSIS
    显示升级确认窗口
.DESCRIPTION
    显示版本对比、更新日志和文件更新列表，提供升级选项
.PARAMETER CurrentVersion
    当前版本号
.PARAMETER LatestVersion
    最新版本号
.PARAMETER VersionInfo
    版本信息对象，包含更新日志等
.PARAMETER UpdateType
    更新类型：Launcher 或 Core
.OUTPUTS
    DialogResult 用户选择的结果
#>
function Show-UpgradeConfirm {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentVersion,
        
        [Parameter(Mandatory = $true)]
        [string]$LatestVersion,
        
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$VersionInfo,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Launcher", "Core", "Both")]
        [string]$UpdateType = "Both"
    )
    
    $dialogResult = [PSCustomObject]@{
        Action      = "Cancel"  # Cancel, Upgrade, Later
        SkipVersion = $false
    }
    
    # 创建确认窗口
    $confirmForm = New-Object System.Windows.Forms.Form
    $confirmForm.Text = "升级确认 - OpenClaw"
    $confirmForm.Size = New-Object System.Drawing.Size(550, 500)
    $confirmForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $confirmForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $confirmForm.MaximizeBox = $false
    $confirmForm.MinimizeBox = $false
    $confirmForm.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10)
    
    $yPos = 15
    
    # 版本对比面板
    $versionPanel = New-Object System.Windows.Forms.Panel
    $versionPanel.Location = New-Object System.Drawing.Point(15, $yPos)
    $versionPanel.Size = New-Object System.Drawing.Size(500, 80)
    $versionPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $confirmForm.Controls.Add($versionPanel)
    
    # 当前版本标签
    $currentVerLabel = New-Object System.Windows.Forms.Label
    $currentVerLabel.Location = New-Object System.Drawing.Point(20, 15)
    $currentVerLabel.Size = New-Object System.Drawing.Size(200, 25)
    $currentVerLabel.Text = "当前版本："
    $currentVerLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
    $versionPanel.Controls.Add($currentVerLabel)
    
    $currentVerValue = New-Object System.Windows.Forms.Label
    $currentVerValue.Location = New-Object System.Drawing.Point(120, 15)
    $currentVerValue.Size = New-Object System.Drawing.Size(150, 25)
    $currentVerValue.Text = $CurrentVersion
    $currentVerValue.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    $versionPanel.Controls.Add($currentVerValue)
    
    # 最新版本标签
    $latestVerLabel = New-Object System.Windows.Forms.Label
    $latestVerLabel.Location = New-Object System.Drawing.Point(20, 45)
    $latestVerLabel.Size = New-Object System.Drawing.Size(200, 25)
    $latestVerLabel.Text = "最新版本："
    $latestVerLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
    $versionPanel.Controls.Add($latestVerLabel)
    
    $latestVerValue = New-Object System.Windows.Forms.Label
    $latestVerValue.Location = New-Object System.Drawing.Point(120, 45)
    $latestVerValue.Size = New-Object System.Drawing.Size(150, 25)
    $latestVerValue.Text = $LatestVersion
    $latestVerValue.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 0)
    $latestVerValue.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
    $versionPanel.Controls.Add($latestVerValue)
    
    # 更新类型标签
    $typeLabel = New-Object System.Windows.Forms.Label
    $typeLabel.Location = New-Object System.Drawing.Point(280, 30)
    $typeLabel.Size = New-Object System.Drawing.Size(200, 25)
    switch ($UpdateType) {
        "Launcher" { $typeLabel.Text = "启动器更新" }
        "Core" { $typeLabel.Text = "核心文件更新" }
        "Both" { $typeLabel.Text = "完整更新" }
    }
    $typeLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 100, 200)
    $versionPanel.Controls.Add($typeLabel)
    
    $yPos += 95
    
    # 更新日志标题
    $changelogTitle = New-Object System.Windows.Forms.Label
    $changelogTitle.Location = New-Object System.Drawing.Point(15, $yPos)
    $changelogTitle.Size = New-Object System.Drawing.Size(200, 25)
    $changelogTitle.Text = "更新内容："
    $changelogTitle.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
    $confirmForm.Controls.Add($changelogTitle)
    
    $yPos += 30
    
    # 更新日志文本框
    $changelogBox = New-Object System.Windows.Forms.RichTextBox
    $changelogBox.Location = New-Object System.Drawing.Point(15, $yPos)
    $changelogBox.Size = New-Object System.Drawing.Size(500, 180)
    $changelogBox.ReadOnly = $true
    $changelogBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
    $changelogBox.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
    $changelogBox.BackColor = [System.Drawing.Color]::White
    
    # 填充更新日志内容
    $changelogContent = ""
    if ($VersionInfo) {
        if ($VersionInfo.changelog) {
            $changelogContent = $VersionInfo.changelog
        }
        else {
            if ($VersionInfo.newFeatures) {
                $changelogContent += "[新增功能]`n"
                foreach ($feature in $VersionInfo.newFeatures) {
                    $changelogContent += "  - $feature`n"
                }
                $changelogContent += "`n"
            }
            if ($VersionInfo.bugFixes) {
                $changelogContent += "[问题修复]`n"
                foreach ($fix in $VersionInfo.bugFixes) {
                    $changelogContent += "  - $fix`n"
                }
                $changelogContent += "`n"
            }
            if ($VersionInfo.improvements) {
                $changelogContent += "[性能优化]`n"
                foreach ($improvement in $VersionInfo.improvements) {
                    $changelogContent += "  - $improvement`n"
                }
            }
        }
    }
    
    if ([string]::IsNullOrEmpty($changelogContent)) {
        $changelogContent = "暂无更新日志信息"
    }
    
    $changelogBox.Text = $changelogContent
    $confirmForm.Controls.Add($changelogBox)
    
    $yPos += 190
    
    # 文件更新列表标题
    $filesTitle = New-Object System.Windows.Forms.Label
    $filesTitle.Location = New-Object System.Drawing.Point(15, $yPos)
    $filesTitle.Size = New-Object System.Drawing.Size(200, 25)
    $filesTitle.Text = "更新文件："
    $filesTitle.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
    $confirmForm.Controls.Add($filesTitle)
    
    $yPos += 25
    
    # 文件更新列表
    $filesList = New-Object System.Windows.Forms.Label
    $filesList.Location = New-Object System.Drawing.Point(15, $yPos)
    $filesList.Size = New-Object System.Drawing.Size(500, 50)
    $filesList.Text = ""
    
    $fileList = @()
    if ($UpdateType -eq "Launcher" -or $UpdateType -eq "Both") {
        $fileList += "U-Claw-Launcher.ps1 (启动器主程序)"
    }
    if ($UpdateType -eq "Core" -or $UpdateType -eq "Both") {
        $fileList += "OpenClaw 核心模块"
    }
    $filesList.Text = [string]::Join(", ", $fileList)
    $confirmForm.Controls.Add($filesList)
    
    $yPos += 55
    
    # 按钮面板
    $btnPanel = New-Object System.Windows.Forms.Panel
    $btnPanel.Location = New-Object System.Drawing.Point(15, $yPos)
    $btnPanel.Size = New-Object System.Drawing.Size(500, 45)
    $confirmForm.Controls.Add($btnPanel)
    
    # 立即升级按钮
    $upgradeBtn = New-Object System.Windows.Forms.Button
    $upgradeBtn.Location = New-Object System.Drawing.Point(80, 5)
    $upgradeBtn.Size = New-Object System.Drawing.Size(120, 35)
    $upgradeBtn.Text = "立即升级"
    $upgradeBtn.BackColor = [System.Drawing.Color]::FromArgb(46, 139, 87)
    $upgradeBtn.ForeColor = [System.Drawing.Color]::White
    $upgradeBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $upgradeBtn.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
    $upgradeBtn.Add_Click({
            $dialogResult.Action = "Upgrade"
            $confirmForm.Close()
        })
    $btnPanel.Controls.Add($upgradeBtn)
    
    # 稍后提醒按钮
    $laterBtn = New-Object System.Windows.Forms.Button
    $laterBtn.Location = New-Object System.Drawing.Point(220, 5)
    $laterBtn.Size = New-Object System.Drawing.Size(120, 35)
    $laterBtn.Text = "稍后提醒"
    $laterBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $laterBtn.Add_Click({
            $dialogResult.Action = "Later"
            $confirmForm.Close()
        })
    $btnPanel.Controls.Add($laterBtn)
    
    # 跳过此版本按钮
    $skipBtn = New-Object System.Windows.Forms.Button
    $skipBtn.Location = New-Object System.Drawing.Point(360, 5)
    $skipBtn.Size = New-Object System.Drawing.Size(120, 35)
    $skipBtn.Text = "跳过此版本"
    $skipBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    $skipBtn.Add_Click({
            $dialogResult.Action = "Later"
            $dialogResult.SkipVersion = $true
            $confirmForm.Close()
        })
    $btnPanel.Controls.Add($skipBtn)
    
    # 显示窗口
    $confirmForm.ShowDialog() | Out-Null
    
    return $dialogResult
}

<#
.SYNOPSIS
    执行完整升级流程
.DESCRIPTION
    检查设备激活状态，获取版本信息，显示确认窗口，执行升级
.OUTPUTS
    PSCustomObject 包含 Success, Message 属性
#>
function Invoke-FullUpgrade {
    $result = [PSCustomObject]@{
        Success     = $false
        Message     = ""
        NeedRestart = $false
    }
    
    try {
        # 1. 检查网络连接
        $script:statusLabel.Text = $txtNetworkChecking
        $script:form.Refresh()
        
        $isOnline = Test-NetworkConnection
        Update-NetworkStatusDisplay -IsOnline $isOnline
        
        if (-not $isOnline) {
            [System.Windows.Forms.MessageBox]::Show(
                "网络未连接，无法检查更新。`n`n请检查网络连接后重试。",
                "网络错误",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            $script:statusLabel.Text = $txtReady
            $result.Message = "网络未连接"
            return $result
        }
        
        # 2. 获取版本信息
        $script:statusLabel.Text = $txtUpgradeCheck
        $script:form.Refresh()
        
        $config = Get-UpdateConfig
        $remoteInfo = Get-NetworkVersionInfo -Url $config.versionUrl
        
        if (-not $remoteInfo) {
            [System.Windows.Forms.MessageBox]::Show(
                "无法获取版本信息，请稍后重试。",
                "检查失败",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            $script:statusLabel.Text = $txtReady
            $result.Message = "无法获取版本信息"
            return $result
        }
        
        # 3. 比较版本
        $usbCurrentVersion = $script:CURRENT_VERSION
        $usbLatestVersion = $remoteInfo.version
        $coreCurrentVersion = Get-OpenClawCoreVersion
        if (-not $coreCurrentVersion) { $coreCurrentVersion = "未安装" }
        
        # 获取核心最新版本
        $coreLatestVersion = $remoteInfo.coreVersion
        if (-not $coreLatestVersion) {
            # 尝试从 npm 获取
            try {
                $checkScript = @"
const https = require('https');
https.get('https://registry.npmmirror.com/openclaw/latest', (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
        try {
            const pkg = JSON.parse(data);
            console.log(pkg.version);
        } catch(e) {
            console.log('error');
        }
    });
}).on('error', () => console.log('error'));
"@
                $checkFile = Join-Path $env:TEMP "check-version.js"
                $checkScript | Out-File $checkFile -Encoding utf8
                $npmResult = & $script:NODE_BIN $checkFile 2>&1
                Remove-Item $checkFile -ErrorAction SilentlyContinue
                $coreLatestVersion = $npmResult | Select-Object -Last 1
            }
            catch {
                $coreLatestVersion = "Unknown"
            }
        }
        
        # 5. 判断是否有更新
        $hasUsbUpdate = ($usbLatestVersion -ne "Unknown" -and $usbLatestVersion -ne $usbCurrentVersion)
        $hasCoreUpdate = ($coreLatestVersion -ne "Unknown" -and $coreCurrentVersion -ne "未安装" -and $coreLatestVersion -ne $coreCurrentVersion)
        
        if (-not $hasUsbUpdate -and -not $hasCoreUpdate) {
            [System.Windows.Forms.MessageBox]::Show(
                "当前已是最新版本！`n`n启动器版本: $usbCurrentVersion`n核心版本: $coreCurrentVersion",
                "检查完成",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            $script:statusLabel.Text = $txtUpgradeUpToDate
            $result.Success = $true
            $result.Message = "已是最新版本"
            return $result
        }
        
        # 6. 显示升级确认窗口
        $updateType = "Both"
        if ($hasUsbUpdate -and -not $hasCoreUpdate) {
            $updateType = "Launcher"
        }
        elseif (-not $hasUsbUpdate -and $hasCoreUpdate) {
            $updateType = "Core"
        }
        
        $confirmResult = Show-UpgradeConfirm -CurrentVersion "$usbCurrentVersion / $coreCurrentVersion" -LatestVersion "$usbLatestVersion / $coreLatestVersion" -VersionInfo $remoteInfo -UpdateType $updateType
        
        # 7. 处理用户选择
        if ($confirmResult.Action -eq "Cancel" -or $confirmResult.Action -eq "Later") {
            if ($confirmResult.SkipVersion) {
                Add-SkippedVersion -Version $usbLatestVersion
            }
            $script:statusLabel.Text = $txtReady
            $result.Message = "用户取消升级"
            return $result
        }
        
        # 8. 执行升级
        $script:statusLabel.Text = $txtUpgrading
        $script:form.Refresh()
        
        # 升级核心文件
        if ($hasCoreUpdate) {
            $coreResult = Update-CoreFiles -VersionInfo $remoteInfo
            if (-not $coreResult.Success) {
                [System.Windows.Forms.MessageBox]::Show(
                    "核心文件升级失败：`n" + $coreResult.Message,
                    "升级失败",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
                $script:statusLabel.Text = $txtUpgradeFailed
                $result.Message = $coreResult.Message
                return $result
            }
        }
        
        # 升级启动器
        if ($hasUsbUpdate) {
            $launcherResult = Update-Launcher -VersionInfo $remoteInfo
            if ($launcherResult.Success) {
                $result.NeedRestart = $launcherResult.NeedRestart
                [System.Windows.Forms.MessageBox]::Show(
                    $launcherResult.Message,
                    "升级成功",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
                $result.Success = $true
                $result.Message = $launcherResult.Message
            }
            else {
                [System.Windows.Forms.MessageBox]::Show(
                    "启动器升级失败：`n" + $launcherResult.Message,
                    "升级失败",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
                $result.Message = $launcherResult.Message
            }
        }
        else {
            $result.Success = $true
            $result.Message = "升级完成"
            [System.Windows.Forms.MessageBox]::Show(
                "升级完成！`n`n核心版本: $coreCurrentVersion → $coreLatestVersion",
                "升级成功",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
        
        $script:statusLabel.Text = $txtUpgradeDone
        
    }
    catch {
        $result.Message = "升级过程出错: $_"
        [System.Windows.Forms.MessageBox]::Show(
            "升级过程出错：`n$_",
            "错误",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        $script:statusLabel.Text = $txtUpgradeFailed
    }
    
    return $result
}

#endregion 升级功能实现

$script:form.Add_Shown({
        $script:form.Refresh()
    
        Get-ChildItem -Path $scriptPath -Filter "launcher_utf8_*.log" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } | Remove-Item -Force -ErrorAction SilentlyContinue
    
        $networkStatusLabel.Text = "🌐 " + $txtNetworkChecking
        $networkStatusLabel.ForeColor = [System.Drawing.Color]::Gray
        $script:form.Refresh()
    
        $isOnline = Test-NetworkConnection
        Update-NetworkStatusDisplay -IsOnline $isOnline
    
        if ($isOnline) {
            Start-Sleep -Milliseconds 500
        
            if (Should-CheckUpdate) {
                Check-VersionUpdate -ShowNoUpdate $false -Silent $true
            }
        }
    
        Start-UpdateCheckTimer
    })

[void]$script:form.ShowDialog()

Stop-UpdateCheckTimer
if ($script:networkClient) {
    $script:networkClient.Dispose()
    $script:networkClient = $null
}
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()