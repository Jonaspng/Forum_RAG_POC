require 'uri'
require 'net/http'

class ForumDataController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:getdata]

  def index
    @data = ForumData.all
    render json: @data
  end

end
