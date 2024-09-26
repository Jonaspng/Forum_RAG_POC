# db/seeds.rb

require "csv"
require "json"

# csv_file_path = Rails.root.join("lib", "seeds", "forum_posts_json.csv")

# Clear the forum_data table
CourseMaterial.delete_all
# ForumData.delete_all

# CSV.foreach(csv_file_path, headers: true) do |row|
#   # Parse the JSON object from the CSV row
#   data = JSON.parse(row["json_data"])
#   embedding = data["question_embedding"]
#   data.delete("question_embedding")
#   data.delete("question")

#   ForumData.create!(
#     embedding: embedding,
#     data: data,
#   )
# end

puts "CSV JSON data has been imported successfully!"
