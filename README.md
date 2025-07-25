# PDF文档RAG智能体

🤖 一个生产级的RAG（检索增强生成）系统，专为PDF文档智能分析而设计，针对中文场景深度优化。

![演示](https://img.shields.io/badge/演示-在线-brightgreen) ![许可证](https://img.shields.io/badge/许可证-MIT-blue) ![Python](https://img.shields.io/badge/python-3.8+-blue) ![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green)

## 📱 产品效果展示

<div align="center">
  <img src="data/image/pdf-agent.png" alt="智能问答界面" width="800"/>
  <p><em>智能问答界面 - 支持PDF文档智能分析与精准问答</em></p>
</div>

## 📋 版本说明

本项目采用渐进式开发策略，不同版本具有不同的技术栈和复杂度：

- **V1版本**：入门级实现，使用ChromaDB作为向量数据库，本地文件存储，适合快速上手
- **V2版本**：中级实现，使用Qdrant作为向量数据库，提供更高性能和可扩展性
- **V3版本**：当前主分支，在V2基础上增加腾讯云COS对象存储和自动化部署脚本，适合生产环境

> 根据需要选择不同版本：
> - 入门学习：`git checkout feature_v1`
> - 中级应用：`git checkout feature_v2`
> - 生产部署：使用主分支

## ✨ 核心特性

- 🔍 **智能文档处理** - PDF解析与智能分块
- 🧠 **RAG管道** - 向量检索 + 大模型生成，精准问答
- 🌐 **多模型支持** - 通义千问 / OpenAI GPT 无缝集成
- 🗄️ **灵活数据库** - 开发用SQLite，生产用PostgreSQL
- 🎯 **中文优化** - 专为中文学术文档设计
- 📱 **现代化界面** - Vue.js前端，实时处理状态
- 💾 **高性能向量存储** - V1版本使用ChromaDB，V2/V3版本升级为Qdrant
- ☁️ **云存储支持** - V3版本支持腾讯云COS对象存储
- 🚀 **自动化部署** - V3版本提供一键部署脚本

## 🚀 快速开始

### 环境要求
- Python 3.8+
- Node.js 16+（可选，用于前端）
- Qdrant（V2/V3版本需要，可本地或远程部署）
- 腾讯云COS（V3版本可选）

### 1. 克隆并配置
```bash
git clone https://github.com/your-username/pdf-document-rag.git
cd pdf-document-rag/backend

# 选择版本
git checkout v1  # 入门版本 (ChromaDB + 本地存储)
git checkout v2  # 中级版本 (Qdrant + 本地存储)
# 主分支为V3版本 (Qdrant + 腾讯云COS + 部署脚本)

# 配置API密钥
cp .env.development .env
nano .env  # 设置必要的API密钥和配置

# 启动后端（本地开发环境）
chmod +x start_local.sh
./start_local.sh
```

### 2. 启动前端（可选）
```bash
cd frontend
npm install && npm run dev
```

### 3. 访问服务
- **API文档**: http://localhost:8000/docs
- **Web界面**: http://localhost:5173

## 📖 使用示例

### 上传文档并查询
```python
import requests

# 上传PDF文档
files = {"file": open("研究论文.pdf", "rb")}
response = requests.post("http://localhost:8000/api/v1/documents/upload", files=files)
doc_id = response.json()["document_id"]

# RAG智能问答
query = {
    "question": "这篇论文的主要发现是什么？",
    "max_results": 5
}
response = requests.post(f"http://localhost:8000/api/v1/documents/{doc_id}/query", json=query)
print(response.json()["answer"])
```

### 核心API接口
- `POST /api/v1/documents/upload` - 上传PDF文档
- `POST /api/v1/documents/{id}/query` - RAG智能问答
- `GET /api/v1/documents/` - 文档列表
- `GET /docs` - 交互式API文档

## ��️ 系统架构

### V1版本架构
```
RAG处理流程 (V1)
┌─────────────┐ ┌──────────────┐ ┌─────────────┐ ┌──────────────┐
│ PDF │ -> │ 文本分块 │ -> │ 向量数据库 │ -> │ 大模型生成 │
│ 文档 │ │ (LangChain) │ │ (ChromaDB) │ │(通义千问/GPT)│
└─────────────┘ └──────────────┘ └─────────────┘ └──────────────┘
```

### V2版本架构
```
RAG处理流程 (V2)
┌─────────────┐ ┌──────────────┐ ┌─────────────┐ ┌──────────────┐
│ PDF │ -> │ 文本分块 │ -> │ 向量数据库 │ -> │ 大模型生成 │
│ 文档 │ │ (LangChain) │ │ (Qdrant)  │ │(通义千问/GPT)│
└─────────────┘ └──────────────┘ └─────────────┘ └──────────────┘
```

### V3版本架构
```
RAG处理流程 (V3)
┌─────────────┐ ┌──────────────┐ ┌─────────────┐ ┌──────────────┐
│ PDF文档 │ -> │ 文本分块 │ -> │ 向量数据库 │ -> │ 大模型生成 │
│(腾讯云COS)│ │ (LangChain) │ │ (Qdrant)  │ │(通义千问/GPT)│
└─────────────┘ └──────────────┘ └─────────────┘ └──────────────┘
```

## 🛠️ 技术栈

**后端**
- FastAPI + SQLAlchemy
- 向量数据库：
  - V1版本：ChromaDB (内嵌式)
  - V2/V3版本：Qdrant (高性能，支持分布式)
- 文件存储：
  - V1/V2版本：本地文件系统
  - V3版本：腾讯云COS对象存储（可选）
- LangChain RAG框架
- 通义千问/OpenAI 大模型推理

**前端**
- Vue.js 3 + TypeScript + Element Plus

**部署**
- V3版本：自动化部署脚本，支持systemd服务或screen会话

## ⚙️ 配置说明

### V1版本配置（ChromaDB + 本地存储）
```env
DASHSCOPE_API_KEY=你的通义千问密钥
LLM_TYPE=qwen
DATABASE_URL=sqlite:///./pdf_analysis.db
CHUNK_SIZE=1000
```

### V2版本配置（Qdrant + 本地存储）
```env
DASHSCOPE_API_KEY=你的通义千问密钥
LLM_TYPE=qwen
DATABASE_URL=sqlite:///./pdf_analysis.db  # 开发环境
# DATABASE_URL=postgresql://user:password@localhost:5432/pdf_analysis  # 生产环境
CHUNK_SIZE=1000
QDRANT_HOST=localhost
QDRANT_PORT=6333
```

### V3版本配置（Qdrant + 腾讯云COS）
```env
# 基础配置
DASHSCOPE_API_KEY=你的通义千问密钥
LLM_TYPE=qwen
DATABASE_URL=postgresql://user:password@localhost:5432/pdf_analysis

# Qdrant配置
QDRANT_HOST=localhost
QDRANT_PORT=6333
QDRANT_HTTPS=false
QDRANT_API_KEY=你的Qdrant密钥

# 腾讯云COS配置
FILE_STORAGE_TYPE=cos  # 使用cos或local
TENCENT_SECRET_ID=你的腾讯云SecretId
TENCENT_SECRET_KEY=你的腾讯云SecretKey
TENCENT_COS_REGION=ap-beijing
TENCENT_COS_BUCKET=your-bucket-name
```

## 🔧 开发指南

### 项目结构

```
├── backend/
│ ├── app/
│ │ ├── core/
│ │ │ ├── vector_store.py # Qdrant向量存储
│ │ │ └── qdrant_adapter.py # Qdrant适配器
│ │ ├── utils/
│ │ │ ├── cos_client.py # V3: 腾讯云COS客户端
│ │ │ └── file_storage.py # V3: 文件存储管理
│ │ └── llm/ # 大模型适配器
│ ├── deploy_production.sh # V3: 生产环境部署脚本
│ ├── manage_service.sh # V3: 服务管理脚本
│ └── requirements.txt
└── frontend/src/ # Vue.js应用
```

### 版本选择指南

- **初学者**：建议使用V1版本，依赖少，配置简单
- **进阶用户**：推荐V2版本，性能更好，可扩展性强
- **生产环境**：强烈推荐V3版本，支持云存储和自动化部署

### 生产环境部署（V3版本）

```bash
# 克隆项目
git clone https://github.com/your-username/pdf-document-rag.git
cd pdf-document-rag/backend

# 配置环境变量
cp .env.example .env.production
nano .env.production  # 设置必要的API密钥和配置

# 一键部署（自动选择systemd或screen模式）
chmod +x deploy_production.sh
./deploy_production.sh

# 管理服务
./manage_service.sh status  # 查看服务状态
./manage_service.sh logs    # 查看日志
./manage_service.sh restart # 重启服务
./manage_service.sh stop    # 停止服务
```

### 扩展系统
- **添加新模型**：在 `app/llm/` 中实现适配器
- **自定义检索**：
  - V1版本：修改 `chroma_vector_store.py`
  - V2/V3版本：修改 `vector_store.py` 和 `qdrant_adapter.py`
- **存储适配**：
  - V3版本：修改 `file_storage.py` 添加其他云存储提供商
- **界面定制**：编辑 `frontend/src/` 中的Vue组件

## 📚 学习价值

本项目展示了以下技术实践：
- **RAG实现** - 完整的检索增强生成流水线
- **向量数据库** - ChromaDB和Qdrant集成与优化
- **大模型集成** - 多厂商LLM抽象层设计
- **文档处理** - PDF解析与智能分块策略
- **异步处理** - FastAPI后台任务处理
- **云存储集成** - 腾讯云COS对象存储的应用
- **自动化部署** - 生产级部署脚本和服务管理
- **渐进式开发** - 从简单实现到高级功能的演进

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/新功能`)
3. 提交更改 (`git commit -m '添加新功能'`)
4. 推送分支 (`git push origin feature/新功能`)
5. 创建 Pull Request

## 📄 开源协议

本项目基于 MIT 协议开源 - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

- [LangChain](https://langchain.com/) - RAG开发框架
- [ChromaDB](https://www.trychroma.com/) - V1版本向量数据库
- [Qdrant](https://qdrant.tech/) - V2/V3版本向量数据库
- [腾讯云COS](https://cloud.tencent.com/product/cos) - V3版本对象存储
- [通义千问](https://tongyi.aliyun.com/) - 中文大模型支持

---

⭐ **如果这个项目对你有帮助，请给个Star支持！**

📧 **有问题？** 欢迎提交 [Issue](https://github.com/your-username/pdf-document-rag/issues) 或发起 [讨论](https://github.com/your-username/pdf-document-rag/discussions)