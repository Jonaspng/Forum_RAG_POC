class VideoCaption < ApplicationRecord
  has_neighbors :embedding

  def self.get_nearest_neighbours(query_embedding)
    VideoCaption.connection.execute("SET hnsw.ef_search = 100")
    nearest_items = VideoCaption.nearest_neighbors(:embedding, query_embedding, distance: "cosine")
      .first(5)
    threshold = 0.4
    filtered_items = nearest_items.select { |item| item.neighbor_distance <= threshold }
    filtered_data = filtered_items.pluck(:data)
    filtered_data
  end
end
