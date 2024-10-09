class Rag::Tools::ForumPostsTool
  extend Langchain::ToolDefinition

  define_function :get_forum_posts, description: "ForumPostsTool: Retrieve the video captions chunks that are semantically closest to the user query." do
    property :user_query, type: "string", description: "user query", required: true
  end

  def initialize
    @client = LANGCHAIN_OPENAI
  end

  def get_forum_posts(user_query:)
    query_embedding = @client.embed(text: user_query, model: "text-embedding-ada-002").embedding
    data = ForumData.get_nearest_neighbours(query_embedding).to_s
    data = "Below are a list of search results from the forum posts knowledge base:" + data
    puts data
    data
  end
end
