class ForumDataController < ApplicationController
  def index
    @data = ForumData.all
    render json: @data
  end

  def show
    @data = ForumData.nearest_neighbors(:embedding, distance: "cosine").first(5)
    render json: @data
  end
end
