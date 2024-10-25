class VideoCaptionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def upload
    youtube_link = params[:link]

    begin
      video_caption_service = Rag::VideoCaptionService.new(youtube_link)
      title = video_caption_service.fetch_title
      captions = video_caption_service.fetch_captions()

      chunking_service = Rag::ChunkingService.new(text: captions)
      chunks = chunking_service.text_chunking
      embeddings = llm_service.generate_embeddings_from_chunks(chunks)
      chunks.each_with_index do |chunk, index|
        VideoCaption.create(embedding: embeddings[index], data: chunk, video_name: title)
      end
      render json: { message: "Video has been processed successfully" }
    rescue StandardError => e
      render json: { error: e }, status: :unprocessable_entity
    end
  end
end
