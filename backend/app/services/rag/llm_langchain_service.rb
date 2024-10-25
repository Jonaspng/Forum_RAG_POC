require "base64"

class Rag::LlmLangchainService
  def initialize(evaluation_service = nil)
    @client = LANGCHAIN_OPENAI
  end

  def get_image_caption(image)
    # Base 64 encode image
    if image.is_a?(String)
      base64_image = Base64.strict_encode64(image)
    else
      base64_image = Base64.strict_encode64(File.read(image.path))
    end

    messages = [
      {
        role: "user",
        content: [
          { type: "text", text: "What is in this image? Do not give a summary of image at the end. Make sure response is less than 80 words" },
          {
            type: "image_url",
            image_url: {
              url: "data:image/jpeg;base64,#{base64_image}",
            },
          },
        ],
      },
    ]

    response = @client.chat(messages: messages).chat_completion
    puts "IMAGE CAPTION HERE"
    puts response
    response
  end

  def generate_embeddings_from_chunks(chunks)
    result = []
    chunks.each_slice(10) do |chunk|
      response = @client.embed(
        text: chunk,
        model: "text-embedding-ada-002",
      )
      for embedding in response.raw_response["data"]
        result.push(embedding["embedding"])
      end
    end
    result
  end
end
