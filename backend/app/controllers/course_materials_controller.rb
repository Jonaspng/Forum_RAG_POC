require "pdf-reader"
require "uri"
require "net/http"

class CourseMaterialsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def upload
    begin
      uploaded_file = params[:file]
      image_option = ActiveModel::Type::Boolean.new.cast(params[:option])
      llm_service = Rag::LlmLangchainService.new
      chunking_service = Rag::ChunkingService.new(file: uploaded_file)
      chunks = chunking_service.file_chunking(image_option)
      embeddings = llm_service.generate_embeddings_from_chunks(chunks)
      chunks.each_with_index do |chunk, index|
        CourseMaterial.create(embedding: embeddings[index], data: chunk, file_name: uploaded_file.original_filename)
      end
      render json: { message: "#{File.extname(uploaded_file.original_filename)} file has been processed successfully" }
    rescue StandardError => e
      render json: { error: e }, status: :unprocessable_entity
    end
  end
end
