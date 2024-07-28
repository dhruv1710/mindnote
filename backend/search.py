from qdrant_client import QdrantClient, models


class Searcher:
    DENSE_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
    SPARSE_MODEL = "prithivida/Splade_PP_en_v1"
    def __init__(self, collection_name):
        self.collection_name = collection_name
        # initialize Qdrant client
        self.qdrant_client = QdrantClient("http://localhost:6333")
        self.qdrant_client.set_model(self.DENSE_MODEL)
        self.qdrant_client.set_sparse_model(self.SPARSE_MODEL)

    def search(self,user: int, text: str):
        search_result = self.qdrant_client.query(
            collection_name=self.collection_name,
            query_text=text,
            query_filter=models.Filter(must=[models.FieldCondition(key='user_id',match=models.MatchValue(value=user))]),  # If you don't want any filters for now
            limit=5,  # 5 the closest results
        )
        # `search_result` contains found vector ids with similarity scores 
        # along with the stored payload
        
        # Select and return metadata
        metadata = [hit.metadata for hit in search_result]
        return metadata