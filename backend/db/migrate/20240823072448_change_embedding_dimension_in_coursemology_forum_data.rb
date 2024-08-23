class ChangeEmbeddingDimensionInCoursemologyForumData < ActiveRecord::Migration[7.2]
  def change
    change_column :forum_data, :embedding, :vector, limit: 1536
  end
end
