class ForumDataController < ApplicationController
  def index
    @data = ForumData.all
    render json: @data
  end

  def show
    question_embedding = params[:question_embedding]
    @data = ForumData.nearest_neighbors(:embedding, question_embedding, distance: "cosine").first(5)
    render json: @data
  end
end
