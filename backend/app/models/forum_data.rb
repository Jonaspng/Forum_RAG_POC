class ForumData < ApplicationRecord
  has_neighbors :embedding

  # search Embedding in database
  def self.get_nearest_neighbours(query_embedding)
    ForumData.connection.execute("SET hnsw.ef_search = 100")
    nearest_items = ForumData.nearest_neighbors(:embedding, query_embedding, distance: "cosine")
      .first(3)
    threshold = 0.4
    filtered_items = nearest_items.select { |item| item.neighbor_distance <= threshold }
    filtered_data = filtered_items.pluck(:data)
    filtered_data
  end
end
