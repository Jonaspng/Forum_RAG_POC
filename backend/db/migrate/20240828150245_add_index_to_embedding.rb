class AddIndexToEmbedding < ActiveRecord::Migration[7.2]
  def change
    add_index :forum_data, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
