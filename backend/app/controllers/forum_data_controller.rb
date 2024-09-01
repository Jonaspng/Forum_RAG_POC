class ForumDataController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:getdata]
  def index
    @data = ForumData.all
    render json: @data
  end

  def getdata
    question_embedding = params[:question_embedding]
    ForumData.connection.execute("SET hnsw.ef_search = 100")
    @data = ForumData.nearest_neighbors(:embedding, question_embedding, distance: "cosine").first(5)
    render json: @data
  end
end
