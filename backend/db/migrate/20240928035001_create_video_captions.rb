class CreateVideoCaptions < ActiveRecord::Migration[7.2]
  def change
    create_table :video_captions do |t|
      t.vector :embedding, limit: 1536  # Add the embedding column with pgvector type
      t.text :data
      t.text :video_name
    end
  end
end
