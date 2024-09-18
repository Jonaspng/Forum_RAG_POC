require "openai"

class Rag::LlmService

  @@llm_system_message = <<~TEXT
    You are an intelligent AI forum-answering agent tasked with assisting students by providing accurate and relevant answers to their queries. 
    You must use function tools to obtain more knowledge about user query. You must use only results returned from function tool to answer queries.
    Here's how you should operate:

    1. Process the Query:
      - When a student submits a question, first analyze the query and decide which tool to call.

    2. Provide an Answer :
      - If the tools returns sufficient information to address the student's question, craft a clear and helpful response based on the retrieved information.
      - Not all information returned by tool is related to the query asked by user. Look through the information returned and decide which is relevant.
      - Ensure your response is accurate, easy to understand.
      - Do not show students the citation of source information from knowledge base.

    3. Handle Insufficient Information:
      - If the result from tools does not contain enough information to provide a satisfactory answer, inform the student that their question has been noted and that a teaching staff member will get back to them with an answer.
      - Use the following message template in this case:
        ```
        "I currently don't have enough information to answer your question. Please wait while a teaching staff member reviews your query and provides a detailed response."
        ```
    4. Maintain Professionalism:
      - Always maintain a professional and polite tone.
      - Be responsive and considerate of the student's needs, ensuring they feel supported.

    Your primary goal is to provide accurate and timely assistance while ensuring that students are aware of the next steps if their questions cannot be answered immediately.
  TEXT


  def self.initialise
    @client = OpenAI::Client.new(
      access_token: ENV['OPENAI_API_KEY'],
      log_errors: true
    )
  end

  def self.generate_embedding(text)
    response = @client.embeddings(
      parameters: {
        model: "text-embedding-ada-002",
        input: text
      }
    )
    response['data'][0]['embedding']
  end

  def self.get_forum_posts(query)
    query_embedding = self.generate_embedding(query)
    data = ForumData.get_nearest_neighbours(query_embedding).to_s
    data = "Below are a list of search results from the forum posts knowledge base:" + data
    data    
  end

  def self.get_course_materials(query)
    query_embedding = self.generate_embedding(query)
    data = CourseMaterial.get_nearest_neighbours(query_embedding).to_s
    data = "Below are a list of search results from the course material knowledge base:" + data
  end

  def self.get_response(query)
    assistant = @client.assistants.create(
      parameters: {
        name: "AI RAG Forum Teaching Assistant",
        model: "gpt-4o", 
        instructions: @@llm_system_message,
        tools: [
          {
            "type": "function",
            "function": {
              "name": "get_forum_posts",
              "description": "Gets the top k semantically nearest forum posts based on user query",
            }
          },
          {
            "type": "function",
            "function": {
              "name": "get_course_materials",
              "description": "Gets the top k semantically nearest chunk of course materials based on user query",
            }
          }
        ],
      }
    )

    assistant_id = assistant["id"]

    # Thread Creation
    thread = @client.threads.create

    thread_id = thread["id"]

    message = @client.messages.create(
      thread_id: thread_id,
      parameters: {
          role: "user",
          content: query
      }
    )["id"]
    
    # Run will submit thread created above
    run = @client.runs.create(
      thread_id: thread_id,
      parameters: {
        assistant_id: assistant_id,
        max_prompt_tokens: 2000,
        max_completion_tokens: 4096
      }
    )

    run_id = run['id']
    
    # waits for run's status
    while true do
      response = @client.runs.retrieve(id: run_id, thread_id: thread_id)
      status = response['status']
      case status
      when 'queued', 'in_progress', 'cancelling'
        puts 'Sleeping'
        sleep 1 # Wait one second and poll again
      when 'completed'
        break # Exit loop and report result to user
      when 'requires_action'
        tools_to_call = response.dig('required_action', 'submit_tool_outputs', 'tool_calls')
        my_tool_outputs = tools_to_call.map { |tool|
            # Call the functions based on the tool's name
            function_name = tool.dig('function', 'name')
            arguments = JSON.parse(
                  tool.dig("function", "arguments"),
                  { symbolize_names: true },
            )
            tool_output = case function_name
            when "get_forum_posts"
              self.get_forum_posts(query)
            when "get_course_materials"
              self.get_course_materials(query)
            end
            
            { tool_call_id: tool['id'], output: tool_output }
        }
        puts my_tool_outputs
        @client.runs.submit_tool_outputs(thread_id: thread_id, run_id: run_id, parameters: { tool_outputs: my_tool_outputs })
      when 'cancelled', 'failed', 'expired'
        puts response['last_error'].inspect
        break # or `exit`
      else
        puts "Unknown status response: #{status}"
        break
      end
    end

    # extracting messages
    messages = @client.messages.list(thread_id: thread_id, parameters: { order: 'asc' })
    puts messages
    latest_response = messages["data"][-1]["content"][0]["text"]["value"]
    latest_response
  end

end