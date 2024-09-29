class VideoCaption < ApplicationRecord
  has_neighbors :embedding

  def self.get_nearest_neighbours(query_embedding)
    VideoCaption.connection.execute("SET hnsw.ef_search = 100")
    data = VideoCaption.nearest_neighbors(:embedding, query_embedding, distance: "cosine")
      .first(5)
      .pluck(:data)
    data
  end
end
