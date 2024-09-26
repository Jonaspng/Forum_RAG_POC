require "pdf-reader"
require "uri"
require "net/http"

class CourseMaterialsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def upload
    uploaded_file = params[:file]
    image_option = params[:option]

    Rag::ChunkingService.initialize(uploaded_file)
    if uploaded_file.content_type == "application/pdf"
      Rag::ChunkingService.fixed_size_chunking(image_option)
      render json: { message: "PDF processed successfully" }
    else
      render json: { error: "Invalid file format. Please upload a PDF." }, status: :unprocessable_entity
    end
  end

  private

  def extract_text_from_pdf(file_path)
    reader = PDF::Reader.new(file_path)
    reader.pages.map(&:text).join(" ")
  end

  def chunk_text(text, chunk_size, overlap_size)
    chunks = []
    start = 0

    while start < text.length
      # Define the chunk with overlap
      chunk = text[start, chunk_size]
      chunks << chunk

      # Move the starting position forward, keeping the overlap
      start += (chunk_size - overlap_size)
    end
    chunks
  end
end
