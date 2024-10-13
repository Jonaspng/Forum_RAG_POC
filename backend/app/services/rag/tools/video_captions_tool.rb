class Rag::Tools::VideoCaptionsTool
  extend Langchain::ToolDefinition

  define_function :get_video_captions, description: "VideoCaptionsTool: Retrieve the video captions chunks that are semantically closest to the user query." do
    property :user_query, type: "string", description: "user query", required: true
  end

  def initialize(evaluation)
    @client = LANGCHAIN_OPENAI
    @evaluation = evaluation
  end

  def get_video_captions(user_query:)
    query_embedding = @client.embed(text: user_query, model: "text-embedding-ada-002").embedding
    data = VideoCaption.get_nearest_neighbours(query_embedding).to_s

    # append to context for evaluation service
    @evaluation.context += data

    data = "Below are a list of search results from the video caption knowledge base:" + data
    puts data
    data
  end
end
