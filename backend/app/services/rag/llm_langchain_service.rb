require "base64"

class Rag::LlmLangchainService
  def initialize
    @client = Langchain_Openai
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

  def get_response(query, file = nil)
    image_caption = ""
    if file
      image_caption = "Attached Image caption: #{get_image_caption(file)}"
    end

    nearest_course_materials = get_course_materials(query + image_caption)
    puts nearest_course_materials

    nearest_forum_posts = get_forum_posts(query + image_caption)
    puts nearest_forum_posts

    messages = [
      {
        "role": "system",
        "content": Langchain::Prompt.load_from_path(file_path: "app/services/rag/prompts/prompt_template.json").format(character: "deadpool"),
      },
      {
        "role": "user",
        "content": nearest_course_materials + nearest_forum_posts + " user query: " + query + image_caption,
      },
    ]

    response = @client.chat(messages: messages).chat_completion
    puts response
    response
  end

  private

  def generate_embedding(text)
    response = @client.embed(
      text: text,
      model: "text-embedding-ada-002",
    )
    response.embedding
  end

  def get_forum_posts(query)
    query_embedding = generate_embedding(query)
    data = ForumData.get_nearest_neighbours(query_embedding).to_s
    data = "Below are a list of search results from the forum posts knowledge base:" + data
    data
  end

  def get_course_materials(query)
    query_embedding = generate_embedding(query)
    data = CourseMaterial.get_nearest_neighbours(query_embedding).to_s
    data = "Below are a list of search results from the course material knowledge base:" + data
  end
end
