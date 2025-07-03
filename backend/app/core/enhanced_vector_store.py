import jieba
import re
from typing import List, Dict, Any, Optional
from .vector_store import VectorStoreManager
from .cache_manager import cache_manager
import logging

logger = logging.getLogger(__name__)

class EnhancedVectorStore(VectorStoreManager):
    """增强的向量存储 - 支持混合检索和缓存"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.cache_manager = cache_manager
    
    def search_similar_chunks_with_cache(
        self, 
        document_id: str, 
        query: str, 
        k: int = 5
    ) -> List[Dict]:
        """带缓存的向量搜索"""
        
        # 检查缓存
        cache_key = self.cache_manager.search_cache_key(document_id, query, k)
        cached_result = self.cache_manager.get(cache_key)
        
        if cached_result:
            logger.info(f"命中搜索缓存: {document_id}")
            return cached_result
        
        # 执行搜索
        results = self.search_similar_chunks(document_id, query, k)
        
        # 缓存结果（1小时）
        self.cache_manager.set(cache_key, results, expire=3600)
        
        return results
    
    def hybrid_search(
        self, 
        document_id: str, 
        query: str, 
        k: int = 5,
        alpha: float = 0.7
    ) -> List[Dict]:
        """混合检索：向量搜索 + 关键词搜索"""
        
        try:
            # 向量搜索
            vector_results = self.search_similar_chunks_with_cache(
                document_id, query, k * 2
            )
            
            # 关键词搜索
            keyword_results = self._keyword_search(document_id, query, k * 2)
            
            # 融合结果
            combined_results = self._combine_search_results(
                vector_results, keyword_results, alpha
            )
            
            return combined_results[:k]
            
        except Exception as e:
            logger.error(f"混合搜索失败: {e}")
            # 降级到普通向量搜索
            return self.search_similar_chunks_with_cache(document_id, query, k)
    
    def _keyword_search(self, document_id: str, query: str, k: int) -> List[Dict]:
        """关键词搜索实现"""
        try:
            collection_name = f"doc_{document_id}"
            
            # 检查集合是否存在
            existing_collections = [col.name for col in self.client.list_collections()]
            if collection_name not in existing_collections:
                return []
            
            # 获取集合
            collection = self.client.get_collection(name=collection_name)
            
            # 获取所有文档
            all_docs = collection.get()
            
            if not all_docs['documents']:
                return []
            
            # 计算关键词匹配分数
            results = []
            for i, content in enumerate(all_docs['documents']):
                score = self._calculate_keyword_score(content, query)
                if score > 0:
                    results.append({
                        "content": content,
                        "metadata": all_docs['metadatas'][i],
                        "similarity_score": score,
                        "chunk_id": all_docs['metadatas'][i].get("chunk_id", ""),
                        "chunk_index": all_docs['metadatas'][i].get("chunk_index", 0)
                    })
            
            # 按分数排序
            results.sort(key=lambda x: x['similarity_score'], reverse=True)
            return results[:k]
            
        except Exception as e:
            logger.error(f"关键词搜索失败: {e}")
            return []
    
    def _calculate_keyword_score(self, content: str, query: str) -> float:
        """计算关键词匹配分数"""
        try:
            # 分词
            query_words = set(jieba.cut(query.lower()))
            content_words = set(jieba.cut(content.lower()))
            
            # 移除停用词和单字符
            stop_words = {'的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个'}
            query_words = {w for w in query_words if len(w) > 1 and w not in stop_words}
            content_words = {w for w in content_words if len(w) > 1 and w not in stop_words}
            
            if not query_words:
                return 0.0
            
            # 计算交集和并集
            intersection = query_words & content_words
            
            if not intersection:
                return 0.0
            
            # 计算Jaccard相似度，并添加词频权重
            jaccard_score = len(intersection) / len(query_words | content_words)
            
            # 添加完全匹配奖励
            exact_matches = sum(1 for word in query_words if word in content.lower())
            exact_match_bonus = exact_matches / len(query_words) * 0.5
            
            return min(jaccard_score + exact_match_bonus, 1.0)
            
        except Exception as e:
            logger.error(f"关键词分数计算失败: {e}")
            return 0.0
    
    def _combine_search_results(
        self, 
        vector_results: List[Dict], 
        keyword_results: List[Dict], 
        alpha: float
    ) -> List[Dict]:
        """融合搜索结果"""
        
        def normalize_scores(results):
            """归一化分数"""
            if not results:
                return results
            
            scores = [r['similarity_score'] for r in results]
            max_score = max(scores) if scores else 1.0
            min_score = min(scores) if scores else 0.0
            
            if max_score == min_score:
                for r in results:
                    r['similarity_score'] = 1.0
                return results
            
            for r in results:
                r['similarity_score'] = (r['similarity_score'] - min_score) / (max_score - min_score)
            
            return results
        
        # 归一化分数
        vector_results = normalize_scores(vector_results.copy())
        keyword_results = normalize_scores(keyword_results.copy())
        
        # 创建内容到结果的映射
        content_map = {}
        
        # 添加向量搜索结果
        for result in vector_results:
            content = result['content']
            content_map[content] = {
                **result,
                'vector_score': result['similarity_score'],
                'keyword_score': 0.0
            }
        
        # 添加关键词搜索结果
        for result in keyword_results:
            content = result['content']
            if content in content_map:
                content_map[content]['keyword_score'] = result['similarity_score']
            else:
                content_map[content] = {
                    **result,
                    'vector_score': 0.0,
                    'keyword_score': result['similarity_score']
                }
        
        # 计算融合分数
        for content, result in content_map.items():
            combined_score = (alpha * result['vector_score'] + 
                            (1 - alpha) * result['keyword_score'])
            result['similarity_score'] = combined_score
        
        # 排序并返回
        final_results = list(content_map.values())
        final_results.sort(key=lambda x: x['similarity_score'], reverse=True)
        
        return final_results 