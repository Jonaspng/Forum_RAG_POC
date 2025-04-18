class Rag::Tools::ForumPostsTool
  extend Langchain::ToolDefinition

  define_function :get_forum_posts, description: "ForumPostsTool: Retrieve the forum posts conversation that are semantically closest to the user query." do
    property :user_query, type: "string", description: "exact user query", required: true
  end

  def initialize(evaluation)
    @client = LANGCHAIN_OPENAI
    @evaluation = evaluation
  end

  def get_forum_posts(user_query:)
    query_embedding = @client.embed(text: user_query, model: "text-embedding-ada-002").embedding
    data = ForumData.get_nearest_neighbours(query_embedding).to_s

    # append to context for evaluation service
    @evaluation.context += data

    data = "Below are a list of search results from the forum posts knowledge base:" + data
    puts data
    data
  end
end
