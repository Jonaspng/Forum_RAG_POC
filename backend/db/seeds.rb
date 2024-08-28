# db/seeds.rb

require 'csv'
require 'json'

csv_file_path = Rails.root.join('lib', 'seeds', 'forum_posts_json.csv')

CSV.foreach(csv_file_path, headers: true) do |row|
  # Parse the JSON object from the CSV row
  data = JSON.parse(row['json_data'])
  embedding = data["embedding"]
  data.delete("embedding")

  # Assuming you have a User model with name, email, and age attributes
  ForumData.create!(
    embedding: embedding,
    data: data
  )
end

puts "CSV JSON data has been imported successfully!"
