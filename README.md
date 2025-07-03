# PDF文档RAG智能体

🤖 一个生产级的RAG（检索增强生成）系统，专为PDF文档智能分析而设计，针对中文场景深度优化。

![演示](https://img.shields.io/badge/演示-在线-brightgreen) ![许可证](https://img.shields.io/badge/许可证-MIT-blue) ![Python](https://img.shields.io/badge/python-3.8+-blue) ![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green)

## 📱 产品效果展示

<div align="center">
  <img src="data/image/pdf-agent.png" alt="智能问答界面" width="800"/>
  <p><em>智能问答界面 - 支持PDF文档智能分析与精准问答</em></p>
</div>

## ✨ 核心特性

- 🔍 **智能文档处理** - PDF解析与智能分块
- 🧠 **RAG管道** - 向量检索 + 大模型生成，精准问答
- 🌐 **多模型支持** - 通义千问 / OpenAI GPT 无缝集成
- 🗄️ **灵活数据库** - 开发用SQLite，生产用PostgreSQL
- 🎯 **中文优化** - 专为中文学术文档设计
- 📱 **现代化界面** - Vue.js前端，实时处理状态

## 🚀 快速开始

### 环境要求
- Python 3.8+
- Node.js 16+（可选，用于前端）

### 1. 克隆并配置
```bash
git clone https://github.com/your-username/pdf-document-rag.git
cd pdf-document-rag/backend

# 配置API密钥
cp .env.development .env
nano .env  # 设置 DASHSCOPE_API_KEY=你的密钥

# 启动后端
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

## 🏗️ 系统架构

```
RAG处理流程
┌─────────────┐ ┌──────────────┐ ┌─────────────┐ ┌──────────────┐
│ PDF │ -> │ 文本分块 │ -> │ 向量数据库 │ -> │ 大模型生成 │
│ 文档 │ │ (LangChain) │ │ (ChromaDB) │ │(通义千问/GPT)│
└─────────────┘ └──────────────┘ └─────────────┘ └──────────────┘
```

## 🛠️ 技术栈

**后端**
- FastAPI + SQLAlchemy + ChromaDB
- LangChain RAG框架
- 通义千问/OpenAI 大模型推理

**前端**
- Vue.js 3 + TypeScript + Element Plus

## ⚙️ 配置说明

主要环境变量：
```env
DASHSCOPE_API_KEY=你的通义千问密钥
LLM_TYPE=qwen
DATABASE_URL=sqlite:///./document_analysis.db
CHUNK_SIZE=1000
```

## 🔧 开发指南

### 项目结构

```
├── backend/
│ ├── app/core/ # RAG核心模块
│ ├── app/llm/ # 大模型适配器
│ └── requirements.txt
└── frontend/src/ # Vue.js应用
```


### 扩展系统
- **添加新模型**：在 `app/llm/` 中实现适配器
- **自定义检索**：修改 `vector_store.py`
- **界面定制**：编辑 `frontend/src/` 中的Vue组件

## 📚 学习价值

本项目展示了以下技术实践：
- **RAG实现** - 完整的检索增强生成流水线
- **向量数据库** - ChromaDB集成与优化
- **大模型集成** - 多厂商LLM抽象层设计
- **文档处理** - PDF解析与智能分块策略
- **异步处理** - FastAPI后台任务处理

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
- [ChromaDB](https://www.trychroma.com/) - 向量数据库
- [通义千问](https://tongyi.aliyun.com/) - 中文大模型支持

---

⭐ **如果这个项目对你有帮助，请给个Star支持！**

📧 **有问题？** 欢迎提交 [Issue](https://github.com/your-username/pdf-document-rag/issues) 或发起 [讨论](https://github.com/your-username/pdf-document-rag/discussions)