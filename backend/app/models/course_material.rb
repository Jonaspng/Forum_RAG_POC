class CourseMaterial < ApplicationRecord
  has_neighbors :embedding

  def self.get_nearest_neighbours(query_embedding)
    CourseMaterial.connection.execute("SET hnsw.ef_search = 100")
    data = CourseMaterial.nearest_neighbors(:embedding, query_embedding, distance: "cosine")
      .first(3)
      .pluck(:data)
    data
  end
end
