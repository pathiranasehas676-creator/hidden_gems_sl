import os
import sys
import unittest
from unittest.mock import MagicMock

# Add current dir to path
sys.path.append(os.path.dirname(__file__))

import vector_retrieval as vr

class TestDynamicRAG(unittest.TestCase):
    def test_firestore_backfill(self):
        # Mock Firestore db
        mock_db = MagicMock()
        mock_doc = MagicMock()
        mock_doc.to_dict.return_value = {
            "title": "Dynamic Hidden Gem",
            "text": "A newly discovered waterfall near Ella.",
            "city": "ella",
            "type": "nature",
            "source_id": "dynamic-fs"
        }
        mock_db.collection.return_value.where.return_value.limit.return_value.get.return_value = [mock_doc]
        
        vr.set_firestore_db(mock_db)
        
        # Mock Qdrant/Model results to be empty
        vr._get_model = MagicMock()
        vr._get_client = MagicMock()
        vr._get_client().search.return_value = []
        
        results = vr.retrieve("ella", ["nature"])
        
        self.assertTrue(any(r["source_id"] == "dynamic-fs" for r in results))
        print("Dynamic Firestore grounding test: PASSED")

if __name__ == "__main__":
    unittest.main()
