class AddCourseMaterialTable < ActiveRecord::Migration[7.2]
  def change
    # Ensure the pgvector extension is enabled
    enable_extension 'vector' unless extension_enabled?('vector')

    # Create the table and add columns in the same migration
    create_table :course_material do |t|
      # Define any initial columns needed for your table
      t.vector :embedding, limit: 1536  # Add the embedding column with pgvector type
      t.text :data
      t.text :file_name
    end
  end
end
