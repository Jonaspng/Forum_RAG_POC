# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_09_28_035001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "course_materials", force: :cascade do |t|
    t.vector "embedding", limit: 1536
    t.text "data"
    t.text "file_name"
  end

  create_table "forum_data", force: :cascade do |t|
    t.vector "embedding", limit: 1536
    t.jsonb "data", default: {}
    t.index ["embedding"], name: "index_forum_data_on_embedding", opclass: :vector_cosine_ops, using: :hnsw
  end

  create_table "video_captions", force: :cascade do |t|
    t.vector "embedding", limit: 1536
    t.text "data"
    t.text "video_name"
  end
end
