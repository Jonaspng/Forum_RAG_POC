class Dbinitialisation < ActiveRecord::Migration[7.2]
  def change
    # Ensure the pgvector extension is enabled
    enable_extension 'vector' unless extension_enabled?('vector')

    # Create the table and add columns in the same migration
    create_table :forum_data do |t|
      # Define any initial columns needed for your table
      t.vector :embedding, limit: 1000  # Add the embedding column with pgvector type
      t.jsonb :data, default: {}  # Add the data column with jsonb type for storing JSON data
    end
  end
end
