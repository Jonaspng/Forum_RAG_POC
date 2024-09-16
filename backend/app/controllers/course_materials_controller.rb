require 'pdf-reader'
require 'uri'
require 'net/http'

class CourseMaterialsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def upload
    uploaded_file = params[:file]
    
    if uploaded_file.content_type == "application/pdf"
      file_path = Rails.root.join('tmp', uploaded_file.original_filename)
      File.open(file_path, 'wb') do |file|
        file.write(uploaded_file.read)
      end

      text = extract_text_from_pdf(file_path)

      text = text.gsub(/\s+/, ' ').strip

      chunks = chunk_text(text, 500, 100)

      for chunk in chunks
        embedding = get_embedding(chunk)
        CourseMaterial.create(embedding: embedding, data: chunk, file_name: uploaded_file.original_filename)
      end

      render json: { message: "PDF processed successfully"}
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

  def get_embedding(text)
    embedding_url = URI("https://api.edenai.run/v2/text/embeddings")
    http = Net::HTTP.new(embedding_url.host, embedding_url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(embedding_url)
    request["accept"] = 'application/json'
    request["content-type"] = 'application/json'
    request["authorization"] = "Bearer #{ENV.fetch('AI_AUTHORISATION')}"
    request.body = {
      response_as_dict: true,
      attributes_as_list: false,
      show_base_64: true,
      show_original_response: false,
      providers: ["openai/1536__text-embedding-ada-002"],
      texts: [text]
  }.to_json
    response = http.request(request)
    question_embedding = JSON.parse(response.read_body)["openai/1536__text-embedding-ada-002"]["items"][0]["embedding"]
    question_embedding
  end

end
