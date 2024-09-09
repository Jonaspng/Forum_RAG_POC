require 'uri'
require 'net/http'

class ForumDataController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:getdata]

  @@llm_system_message = <<~TEXT
    You are an intelligent AI forum-answering agent tasked with assisting students by providing accurate and relevant answers to their queries based on the information available in the knowledge base. Here's how you should operate:

    1. **Process the Query:**
      - When a student submits a question, first analyze the query and search the provided knowledge base for relevant information.

    2. **Provide an Answer:**
      - If the knowledge base contains sufficient information to address the student's question, craft a clear and helpful response based on that information.
      - Ensure your response is detailed, accurate, and easy to understand.

    3. **Handle Insufficient Information:**
      - If the knowledge base does not contain enough information to provide a satisfactory answer, inform the student that their question has been noted and that a teaching staff member will get back to them with an answer.
      - Use the following message template in this case:
        ```
        "I currently don't have enough information to answer your question. Please wait while a teaching staff member reviews your query and provides a detailed response."
        ```
    4. **Maintain Professionalism:**
      - Always maintain a professional and polite tone.
      - Be responsive and considerate of the student's needs, ensuring they feel supported.

    Your primary goal is to provide accurate and timely assistance while ensuring that students are aware of the next steps if their questions cannot be answered immediately.

  TEXT

  @@llm_knowledge_base_prompt = <<~TEXT
    Below are a list of search results from the knowledge base:
  TEXT

  def index
    @data = ForumData.all
    render json: @data
  end

  def getdata
    # get Embedding
    embedding_url = URI("https://api.edenai.run/v2/text/embeddings")
    question = params[:question]
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
      texts: [question]
  }.to_json
    response = http.request(request)
    question_embedding = JSON.parse(response.read_body)["openai/1536__text-embedding-ada-002"]["items"][0]["embedding"]
    
    # search Embedding in database
    ForumData.connection.execute("SET hnsw.ef_search = 100")
    @data = ForumData.nearest_neighbors(:embedding, question_embedding, distance: "cosine")
            .first(5)
            .pluck(:data)
    puts @data

    # provide search result to LLM
    llm_url = URI("https://api.edenai.run/v2/text/chat")
    request = Net::HTTP::Post.new(llm_url)
    request["accept"] = 'application/json'
    request["content-type"] = 'application/json'
    request["authorization"] = "Bearer #{ENV.fetch('AI_AUTHORISATION')}"
    request.body = {
      response_as_dict: true,
      providers: ["openai/gpt-4o"],
      attributes_as_list: false,
      show_base_64: true,
      show_original_response: false,
      temperature: 0,
      max_tokens: 2000,
      tool_choice: "auto",
      text: @@llm_knowledge_base_prompt + @data.to_s + "question: #{question}",
      chatbot_global_action: @@llm_system_message,
      previous_history: []
    }.to_json
    response = http.request(request)
    
    puts response.read_body

    # get LLm response
    render json: response.read_body
  end
end
