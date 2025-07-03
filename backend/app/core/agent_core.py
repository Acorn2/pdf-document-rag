from langchain.prompts import ChatPromptTemplate
from langchain.schema.output_parser import StrOutputParser
from typing import List, Dict, Optional
import time
import logging
from .vector_store import VectorStoreManager
from .model_factory import ModelFactory

logger = logging.getLogger(__name__)

class DocumentAnalysisAgent:
    """文档分析智能体 - 支持多种大模型"""
    
    def __init__(
        self, 
        vector_store_manager: VectorStoreManager,
        llm_type: str = None,
        model_config: dict = None
    ):
        self.vector_store = vector_store_manager
        
        # 使用模型工厂创建LLM
        self.llm = ModelFactory.create_llm(
            model_type=llm_type,
            **(model_config or {})
        )
        
        # 针对通义千问优化的中文提示词
        if llm_type and llm_type.lower() == "qwen":
            self.qa_prompt = ChatPromptTemplate.from_template("""
你是一个专业的中文文献分析助手，具备深厚的学术背景和文献理解能力。请基于提供的文档内容，准确、专业地回答用户的问题。

文档相关内容：
{context}

用户问题：{question}

回答要求：
1. 严格基于提供的文档内容进行回答，不要添加文档中没有的信息
2. 如果文档中缺少相关信息，请明确指出并说明
3. 保持回答的学术性和客观性，使用准确的专业术语
4. 适当引用原文关键段落支持你的回答
5. 回答要条理清晰，重点突出，便于理解
6. 如果问题涉及多个方面，请分点详细说明

回答：
""")
            
            self.summary_prompt = ChatPromptTemplate.from_template("""
请为以下学术文档生成一份高质量的中文摘要：

文档内容：
{content}

摘要要求：
1. 准确概括文档的核心观点、主要发现和重要结论
2. 突出文档的学术价值和创新点
3. 保持逻辑结构清晰，语言表达准确
4. 摘要长度控制在300-600字之间
5. 使用规范的学术写作风格
6. 如果涉及数据或实验结果，请准确提及

摘要：
""")
        else:
            # 保持原有的通用提示词
            self.qa_prompt = ChatPromptTemplate.from_template("""
你是一个专业的文档分析助手。基于以下文档内容，请准确回答用户的问题。

文档相关内容：
{context}

用户问题：{question}

请遵循以下要求：
1. 基于提供的文档内容进行回答
2. 如果文档中没有相关信息，请明确说明
3. 保持回答的准确性和客观性
4. 如果需要，可以引用具体的文档段落
5. 回答要简洁明了，重点突出

回答：
""")
            
            self.summary_prompt = ChatPromptTemplate.from_template("""
请为以下文档内容生成一个简洁而全面的摘要：

文档内容：
{content}

摘要要求：
1. 突出文档的主要观点和核心内容
2. 保持逻辑清晰，结构合理
3. 长度控制在200-500字之间
4. 使用简洁明了的语言

摘要：
""")
    
    def answer_question(
        self, 
        document_id: str, 
        question: str, 
        max_results: int = 5
    ) -> Dict:
        """回答基于文档的问题"""
        start_time = time.time()
        
        try:
            # 1. 向量搜索相关内容
            search_results = self.vector_store.search_similar_chunks(
                document_id=document_id,
                query=question,
                k=max_results
            )
            
            if not search_results:
                return {
                    "answer": "抱歉，在该文档中未找到与您问题相关的内容。",
                    "confidence": 0.0,
                    "sources": [],
                    "processing_time": time.time() - start_time,
                    "success": True
                }
            
            # 2. 构建上下文
            context = self._build_context(search_results)
            
            # 3. 生成回答 - 兼容不同模型接口
            try:
                # 尝试使用LangChain链式调用
                chain = self.qa_prompt | self.llm | StrOutputParser()
                answer = chain.invoke({
                    "context": context,
                    "question": question
                })
            except Exception as e:
                # 降级到直接调用模型
                logger.warning(f"链式调用失败，使用直接调用: {str(e)}")
                prompt_text = self.qa_prompt.format(context=context, question=question)
                answer = self.llm.predict(prompt_text)
            
            # 4. 计算置信度
            confidence = self._calculate_confidence(search_results)
            
            # 5. 准备源信息
            sources = self._prepare_sources(search_results)
            
            processing_time = time.time() - start_time
            
            return {
                "answer": answer.strip(),
                "confidence": confidence,
                "sources": sources,
                "processing_time": processing_time,
                "success": True,
                "error": None
            }
            
        except Exception as e:
            logger.error(f"问答处理失败: {str(e)}")
            return {
                "answer": "处理问题时发生错误，请稍后重试。",
                "confidence": 0.0,
                "sources": [],
                "processing_time": time.time() - start_time,
                "success": False,
                "error": str(e)
            }
    
    def generate_summary(self, document_id: str) -> Dict:
        """生成文档摘要"""
        try:
            # 获取文档的所有块（用于生成摘要）
            search_results = self.vector_store.search_similar_chunks(
                document_id=document_id,
                query="文档主要内容 核心观点 关键信息",
                k=10
            )
            
            if not search_results:
                return {
                    "summary": "无法生成摘要：文档内容为空或未找到。",
                    "success": False
                }
            
            # 构建内容
            content = "\n\n".join([result["content"] for result in search_results[:5]])
            
            # 生成摘要
            chain = self.summary_prompt | self.llm | StrOutputParser()
            summary = chain.invoke({"content": content})
            
            return {
                "summary": summary.strip(),
                "success": True,
                "error": None
            }
            
        except Exception as e:
            logger.error(f"摘要生成失败: {str(e)}")
            return {
                "summary": "生成摘要时发生错误。",
                "success": False,
                "error": str(e)
            }
    
    def _build_context(self, search_results: List[Dict]) -> str:
        """构建问答上下文"""
        context_parts = []
        
        for i, result in enumerate(search_results, 1):
            context_parts.append(
                f"段落 {i} (相似度: {result['similarity_score']:.3f}):\n"
                f"{result['content']}\n"
            )
        
        return "\n".join(context_parts)
    
    def _calculate_confidence(self, search_results: List[Dict]) -> float:
        """计算回答置信度"""
        if not search_results:
            return 0.0
        
        # 基于最高相似度分数计算置信度
        max_score = max(result["similarity_score"] for result in search_results)
        
        # 将相似度分数转换为置信度（0-1范围）
        # 这里使用简单的映射，可以根据实际情况调整
        confidence = min(max_score * 2, 1.0)
        
        return round(confidence, 3)
    
    def _prepare_sources(self, search_results: List[Dict]) -> List[Dict]:
        """准备源信息"""
        sources = []
        
        for result in search_results:
            sources.append({
                "chunk_id": result["chunk_id"],
                "chunk_index": result["chunk_index"],
                "similarity_score": result["similarity_score"],
                "content_preview": result["content"][:200] + "..." if len(result["content"]) > 200 else result["content"]
            })
        
        return sources 