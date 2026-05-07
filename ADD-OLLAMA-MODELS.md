# OpenClaw 添加本地 Ollama 中大模型详细步骤

本文档详细介绍如何在 OpenClaw UClaw 便携版中添加和使用本地 Ollama 中大模型。

## 📋 目录

- [一、Ollama 简介](#一ollama-简介)
- [二、安装 Ollama](#二安装-ollama)
- [三、启动 Ollama 服务](#三启动-ollama-服务)
- [四、拉取大模型](#四拉取大模型)
- [五、配置 OpenClaw 使用 Ollama](#五配置-openclaw-使用-ollama)
- [六、验证配置](#六验证配置)
- [七、常见问题](#七常见问题)

---

## 一、Ollama 简介

Ollama 是一款本地大模型运行工具，支持：
- ✅ 在本地运行各种开源大模型（如 Llama、Qwen、Gemma 等）
- ✅ 无需 GPU 加速即可运行（但有 GPU 会更快）
- ✅ 支持模型量化，减小内存占用
- ✅ 与 OpenClaw 无缝集成

### 推荐的中大模型

| 模型 | 参数量 | 内存需求 | 适用场景 |
|------|--------|----------|----------|
| **qwen2.5:7b** | 7B | 6GB+ | 日常对话、代码编写 |
| **qwen2.5:14b** | 14B | 12GB+ | 专业写作、复杂推理 |
| **qwen2.5:32b** | 32B | 24GB+ | 高质量输出、深度分析 |
| **llama3.1:8b** | 8B | 8GB+ | 通用对话、多语言 |
| **llama3.1:70b** | 70B | 48GB+ | 高质量生成、专业领域 |
| **gemma4:9b** | 9B | 10GB+ | 指令遵循、推理 |
| **deepseek-r1:14b** | 14B | 16GB+ | 深度推理、数学问题 |

---

## 二、安装 Ollama

### 2.1 下载 Ollama

访问 Ollama 官网下载：https://ollama.com/download

或者直接下载 Windows 版本：
```
https://github.com/ollama/ollama/releases
```

### 2.2 安装步骤

1. 下载 `OllamaSetup.exe` 安装包
2. 双击运行安装程序
3. 默认安装到 `C:\Users\你的用户名\AppData\Local\Programs\Ollama`
4. 安装程序会自动添加环境变量

### 2.3 验证安装

打开 PowerShell 或命令提示符，输入：

```powershell
ollama --version
```

应该显示类似：
```
ollama version 0.5.6
```

---

## 三、启动 Ollama 服务

### 3.1 自动启动

安装后 Ollama 会自动在后台运行，默认监听端口：**11434**

### 3.2 手动启动

如果 Ollama 没有自动启动，手动启动：

```powershell
ollama serve
```

### 3.3 验证服务状态

新开一个终端窗口，输入：

```powershell
curl http://localhost:11434/api/tags
```

如果返回 JSON 数据，说明 Ollama 服务正常运行。

---

## 四、拉取大模型

### 4.1 常用命令

```powershell
# 查看当前已安装的模型
ollama list

# 拉取模型（以 qwen2.5:7b 为例）
ollama pull qwen2.5:7b

# 拉取其他推荐模型
ollama pull llama3.1:8b
ollama pull qwen2.5:14b
ollama pull deepseek-r1:14b
ollama pull gemma4:9b
```

### 4.2 拉取时间说明

- 首次拉取需要下载模型文件
- 7B 模型：约 4-8 GB，取决于网络速度
- 14B 模型：约 8-16 GB
- 32B 模型：约 16-32 GB

### 4.3 拉取特定版本

```powershell
# 拉取指定标签版本
ollama pull qwen2.5:7b-instruct
ollama pull qwen2.5:14b-chat
```

---

## 五、配置 OpenClaw 使用 Ollama

### 5.1 方法一：自动发现（推荐新手）

最简单的方式，只需设置环境变量：

```powershell
# 设置 Ollama API 密钥（本地使用占位符）
$env:OLLAMA_API_KEY = "ollama-local"
```

然后在 OpenClaw 启动器中：
1. 点击"切换 AI 模型"按钮
2. 选择 Ollama 提供商
3. OpenClaw 会自动发现本地模型

### 5.2 方法二：手动配置（推荐高级用户）

#### 步骤 1：打开配置目录

OpenClaw 配置文件位于：
```
d:\迅雷云盘\u盘\OpenClaw U盘版\U盘版OpenClaw\data\.openclaw\
```

#### 步骤 2：创建或编辑配置文件

创建或修改 `models.json` 文件：

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434",
      "apiKey": "ollama-local",
      "api": "ollama",
      "timeoutSeconds": 300,
      "models": [
        {
          "id": "qwen2.5:7b",
          "name": "qwen2.5:7b",
          "input": ["text"],
          "contextWindow": 32768,
          "maxTokens": 8192,
          "params": {
            "num_ctx": 32768,
            "keep_alive": "15m"
          }
        },
        {
          "id": "qwen2.5:14b",
          "name": "qwen2.5:14b",
          "input": ["text"],
          "contextWindow": 32768,
          "maxTokens": 8192,
          "params": {
            "num_ctx": 32768,
            "keep_alive": "15m"
          }
        },
        {
          "id": "llama3.1:8b",
          "name": "llama3.1:8b",
          "input": ["text"],
          "contextWindow": 32768,
          "maxTokens": 8192,
          "params": {
            "num_ctx": 32768,
            "keep_alive": "15m"
          }
        }
      ]
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/qwen2.5:7b",
        "fallbacks": ["ollama/llama3.1:8b"]
      }
    }
  }
}
```

#### 步骤 3：配置参数说明

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| `baseUrl` | Ollama 服务地址 | `http://localhost:11434` |
| `timeoutSeconds` | 请求超时时间（秒） | 300（本地模型建议设长一些） |
| `contextWindow` | 上下文窗口大小 | 根据模型设置 |
| `num_ctx` | Ollama 运行时上下文 | 建议 32768 或更低 |
| `keep_alive` | 模型保持加载时间 | `"15m"`（15分钟） |

### 5.3 方法三：使用 OpenClaw 命令行

```powershell
# 进入 OpenClaw 目录
cd "d:\迅雷云盘\u盘\OpenClaw U盘版\U盘版OpenClaw\app\core"

# 列出可用模型
.\openclaw models list --provider ollama

# 设置默认模型
.\openclaw models set ollama/qwen2.5:7b
```

---

## 六、验证配置

### 6.1 检查 Ollama 服务

```powershell
# 查看已安装的模型
ollama list

# 测试模型运行
ollama run qwen2.5:7b "你好，请介绍一下自己"
```

### 6.2 检查 OpenClaw 配置

```powershell
# 查看模型状态
.\openclaw models status

# 查看模型列表
.\openclaw models list
```

### 6.3 快速测试

在 OpenClaw 中：
1. 启动 OpenClaw
2. 选择"切换 AI 模型"
3. 选择你配置的 Ollama 模型（如 `ollama/qwen2.5:7b`）
4. 发送一条测试消息验证是否正常工作

---

## 七、常见问题

### Q1: Ollama 服务无法启动

**解决方案**：
```powershell
# 检查 Ollama 是否在运行
tasklist | findstr ollama

# 如果没有，手动启动
ollama serve

# 检查端口占用
netstat -ano | findstr 11434
```

### Q2: 模型下载失败

**解决方案**：
```powershell
# 使用代理下载
$env:HTTP_PROXY = "http://你的代理地址:端口"
$env:HTTPS_PROXY = "http://你的代理地址:端口"

# 重新拉取
ollama pull qwen2.5:7b
```

### Q3: 模型响应很慢

**解决方案**：
1. 确保模型已完全加载（首次响应较慢）
2. 增加 `keep_alive` 时间
3. 减小 `num_ctx` 值降低内存占用
4. 考虑使用量化版本（如 `qwen2.5:7b-q4_K_M`）

### Q4: OpenClaw 无法发现 Ollama 模型

**解决方案**：
1. 确保 Ollama 服务正在运行
2. 检查防火墙设置，允许 11434 端口
3. 使用手动配置方式（方法二）

### Q5: 内存不足

**解决方案**：
1. 关闭其他占用内存的程序
2. 使用更小的模型（如 7B 而非 14B）
3. 使用量化版本减小内存占用
4. 增加系统虚拟内存

### Q6: 如何查看模型支持的功能？

```powershell
# 查看模型信息
ollama show qwen2.5:7b
```

---

## 🎯 推荐配置方案

### 方案一：日常使用（8GB+ 内存）

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434",
      "apiKey": "ollama-local",
      "api": "ollama",
      "timeoutSeconds": 300,
      "models": [
        {
          "id": "qwen2.5:7b",
          "name": "通义千问 7B",
          "input": ["text"],
          "contextWindow": 32768,
          "maxTokens": 8192
        }
      ]
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/qwen2.5:7b"
      }
    }
  }
}
```

### 方案二：高性能需求（16GB+ 内存）

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434",
      "apiKey": "ollama-local",
      "api": "ollama",
      "timeoutSeconds": 420,
      "models": [
        {
          "id": "qwen2.5:14b",
          "name": "通义千问 14B",
          "input": ["text"],
          "contextWindow": 32768,
          "maxTokens": 8192
        },
        {
          "id": "deepseek-r1:14b",
          "name": "DeepSeek 推理 14B",
          "input": ["text"],
          "reasoning": true,
          "contextWindow": 32768,
          "maxTokens": 8192
        }
      ]
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/qwen2.5:14b",
        "fallbacks": ["ollama/deepseek-r1:14b"]
      }
    }
  }
}
```

---

## 📚 相关资源

- [Ollama 官方文档](https://github.com/ollama/ollama)
- [OpenClaw Ollama 集成文档](https://docs.openclaw.ai/providers/ollama)
- [模型库](https://ollama.com/library)

---

## ✅ 快速检查清单

- [ ] Ollama 已安装并运行
- [ ] 已拉取需要的模型
- [ ] OpenClaw 配置文件中已添加 Ollama 配置
- [ ] 可以正常切换到 Ollama 模型
- [ ] 可以正常对话测试

---

© 2026 OpenClaw Team
