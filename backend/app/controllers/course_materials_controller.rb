require "pdf-reader"
require "uri"
require "net/http"

class CourseMaterialsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def upload
    uploaded_file = params[:file]
    image_option = ActiveModel::Type::Boolean.new.cast(params[:option])

    chunking_service = Rag::ChunkingService.new(file: uploaded_file)
    chunks = chunking_service.file_chunking(image_option)
    if chunks
      for chunk in chunks
        embedding = Rag::LlmService.generate_embedding(chunk)
        CourseMaterial.create(embedding: embedding, data: chunk, file_name: uploaded_file.original_filename)
      end
      render json: { message: "#{File.extname(uploaded_file.original_filename)} file processed successfully" }
    else
      render json: { error: "Something went wrong while processing the file" }, status: :unprocessable_entity
    end
  end
end
