require "base64"

class Rag::LlmLangchainService
  def initialize
    @client = LANGCHAIN_OPENAI

    # Define Tools
    course_materials_tool = Rag::Tools::CourseMaterialsTool.new
    forum_posts_tool = Rag::Tools::ForumPostsTool.new
    video_captions_tool = Rag::Tools::VideoCaptionsTool.new

    @assistant = Langchain::Assistant.new(
      llm: @client,
      instructions: Langchain::Prompt.load_from_path(file_path: "app/services/rag/prompts/forum_assistant_system_prompt.json").format(character: "deadpool"),
      tools: [forum_posts_tool, course_materials_tool, video_captions_tool],
    )
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

  def get_assistant_response(query, file = nil)
    image_caption = ""
    if file
      image_caption = "Attached Image caption: #{get_image_caption(file)}"
    end

    query = query + image_caption

    @assistant.add_message_and_run!(content: query)

    puts @assistant.messages.last.content
    @assistant.messages.last.content
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
        "content": Langchain::Prompt.load_from_path(file_path: "app/services/rag/prompts/forum_assistant_system_prompt.json").format(character: "deadpool"),
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
    data
  end
end
