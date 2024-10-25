class CourseMaterial < ApplicationRecord
  has_neighbors :embedding

  def self.get_nearest_neighbours(query_embedding, file_name: nil)
    CourseMaterial.connection.execute("SET hnsw.ef_search = 100")
    nearest_items = if file_name
        CourseMaterial.where(file_name: file_name)
          .nearest_neighbors(:embedding, query_embedding, distance: "cosine")
          .first(5)
      else
        CourseMaterial.nearest_neighbors(:embedding, query_embedding, distance: "cosine")
          .first(5)
      end
    threshold = 0.4
    filtered_items = nearest_items.select { |item| item.neighbor_distance <= threshold }
    filtered_data = filtered_items.pluck(:data)
    filtered_data
  end

  def self.get_course_materials_list()
    CourseMaterial.select(:file_name).distinct.pluck(:file_name)
  end
end
