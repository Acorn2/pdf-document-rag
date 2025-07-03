import os
import chromadb
from chromadb.config import Settings
from langchain.vectorstores import Chroma
from typing import List, Dict, Optional
import logging
from .model_factory import ModelFactory

logger = logging.getLogger(__name__)

class VectorStoreManager:
    """向量存储管理器 - 支持多种嵌入模型"""
    
    def __init__(
        self, 
        persist_directory: str = "./vector_db",
        embedding_type: str = None,
        embedding_config: dict = None
    ):
        self.persist_directory = persist_directory
        
        # 使用模型工厂创建嵌入模型
        self.embeddings = ModelFactory.create_embeddings(
            model_type=embedding_type,
            **(embedding_config or {})
        )
        
        # 确保目录存在
        os.makedirs(persist_directory, exist_ok=True)
        
        # 初始化ChromaDB客户端
        self.client = chromadb.PersistentClient(path=persist_directory)
        
    def create_document_collection(self, document_id: str) -> bool:
        """为文档创建向量集合"""
        try:
            collection_name = f"doc_{document_id}"
            
            # 检查集合是否已存在
            existing_collections = [col.name for col in self.client.list_collections()]
            if collection_name in existing_collections:
                logger.info(f"集合 {collection_name} 已存在")
                return True
            
            # 创建新集合
            self.client.create_collection(
                name=collection_name,
                metadata={"document_id": document_id}
            )
            
            logger.info(f"成功创建集合: {collection_name}")
            return True
            
        except Exception as e:
            logger.error(f"创建向量集合失败: {str(e)}")
            return False
    
    def add_document_chunks(self, document_id: str, chunks: List[Dict]) -> bool:
        """将文档块添加到向量存储"""
        try:
            collection_name = f"doc_{document_id}"
            
            # 准备数据
            texts = [chunk["content"] for chunk in chunks]
            metadatas = [
                {
                    "chunk_id": chunk["chunk_id"],
                    "chunk_index": chunk["chunk_index"],
                    "document_id": document_id,
                    "chunk_length": chunk["chunk_length"]
                }
                for chunk in chunks
            ]
            ids = [chunk["chunk_id"] for chunk in chunks]
            
            # 创建LangChain向量存储
            vector_store = Chroma(
                collection_name=collection_name,
                embedding_function=self.embeddings,
                client=self.client
            )
            
            # 添加文档
            vector_store.add_texts(
                texts=texts,
                metadatas=metadatas,
                ids=ids
            )
            
            logger.info(f"成功添加 {len(chunks)} 个文档块到向量存储")
            return True
            
        except Exception as e:
            logger.error(f"添加文档块到向量存储失败: {str(e)}")
            return False
    
    def search_similar_chunks(
        self, 
        document_id: str, 
        query: str, 
        k: int = 5
    ) -> List[Dict]:
        """搜索相似的文档块"""
        try:
            collection_name = f"doc_{document_id}"
            
            # 检查集合是否存在
            existing_collections = [col.name for col in self.client.list_collections()]
            if collection_name not in existing_collections:
                logger.warning(f"集合 {collection_name} 不存在")
                return []
            
            # 创建向量存储实例
            vector_store = Chroma(
                collection_name=collection_name,
                embedding_function=self.embeddings,
                client=self.client
            )
            
            # 执行相似性搜索
            results = vector_store.similarity_search_with_score(
                query=query,
                k=k
            )
            
            # 添加调试日志
            logger.info(f"搜索到 {len(results)} 个结果")
            for i, (doc, score) in enumerate(results[:2]):  # 只打印前2个
                logger.info(f"结果 {i+1}: content前100字符: {doc.page_content[:100]}")
                logger.info(f"结果 {i+1}: metadata: {doc.metadata}")
            
            # 格式化结果
            formatted_results = []
            for doc, score in results:
                # 确保chunk_index是整数类型
                chunk_index = doc.metadata.get("chunk_index", 0)
                if isinstance(chunk_index, str):
                    chunk_index = int(chunk_index)
                
                formatted_results.append({
                    "content": doc.page_content,
                    "metadata": doc.metadata,
                    "similarity_score": float(score),
                    "chunk_id": doc.metadata.get("chunk_id", ""),
                    "chunk_index": chunk_index  # 确保是数字类型
                })
            
            return formatted_results
            
        except Exception as e:
            logger.error(f"向量搜索失败: {str(e)}")
            return []
    
    def delete_document_collection(self, document_id: str) -> bool:
        """删除文档的向量集合"""
        try:
            collection_name = f"doc_{document_id}"
            
            # 检查集合是否存在
            existing_collections = [col.name for col in self.client.list_collections()]
            if collection_name not in existing_collections:
                logger.info(f"集合 {collection_name} 不存在，无需删除")
                return True
            
            # 删除集合
            self.client.delete_collection(name=collection_name)
            logger.info(f"成功删除集合: {collection_name}")
            return True
            
        except Exception as e:
            logger.error(f"删除向量集合失败: {str(e)}")
            return False
    
    def get_collection_stats(self, document_id: str) -> Dict:
        """获取集合统计信息"""
        try:
            collection_name = f"doc_{document_id}"
            collection = self.client.get_collection(name=collection_name)
            
            return {
                "collection_name": collection_name,
                "document_count": collection.count(),
                "metadata": collection.metadata
            }
            
        except Exception as e:
            logger.error(f"获取集合统计信息失败: {str(e)}")
            return {} 