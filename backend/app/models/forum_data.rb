class ForumData < ApplicationRecord
  has_neighbors :embedding

  # search Embedding in database
  def self.get_nearest_neighbours(query_embedding)
    ForumData.connection.execute("SET hnsw.ef_search = 100")
    data = ForumData.nearest_neighbors(:embedding, query_embedding, distance: "cosine")
      .first(5)
      .pluck(:data)
    data
  end
end
