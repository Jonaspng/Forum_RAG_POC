require "base64"

class Rag::LlmService
  @@llm_system_message = <<~TEXT
    You are an intelligent AI forum-answering agent tasked with assisting students by providing accurate and relevant answers to their queries.
    You are to impersonate deadpool when answering user queries.
    Here's how you should operate:
    
    1. Process the Query:
      - When a student submits a question, first analyze the query and decide which tool to call.
    
    2. Provide an Answer :
      - If there is sufficient information to address the student's question, craft a clear and helpful response based on the retrieved information.
      - Not all information is related to the query asked by user. Look through the information returned and decide which is relevant.
      - Ensure your response is accurate, easy to understand.
      - Do not show students the citation of source information from knowledge base.
    
    3. Handle Insufficient Information:
      - If the information provided does not contain enough information to provide a satisfactory answer, inform the student that their question has been noted and that a teaching staff member will get back to them with an answer.
    
    Your primary goal is to provide accurate and timely assistance while ensuring that students are aware of the next steps if their questions cannot be answered immediately.
  TEXT

  def self.get_image_caption(image)
    # Base 64 encode image
    if image.is_a?(String)
      base64_image = Base64.strict_encode64(image)
    else
      base64_image = Base64.strict_encode64(File.read(image.path))
    end

    messages = [
      {
        "type": "text",
        "text": "What is in this image? Do not give a summary of image at the end.
        Make sure response is less than 80 words",
      },
      { "type": "image_url",
       "image_url": {
        "url": "data:image/jpeg;base64,#{base64_image}",
      } },
    ]

    response = OPENAI_CLIENT.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: messages,
          },
        ],
      },
    )
    puts "IMAGE CAPTION HERE"
    puts response.dig("choices", 0, "message", "content")
    response.dig("choices", 0, "message", "content")
  end

  def self.get_response(query, file = nil)
    image_caption = ""
    if file
      image_caption = "Attached Image caption: #{self.get_image_caption(file)}"
    end

    nearest_course_materials = get_course_materials(query + image_caption)
    puts nearest_course_materials

    nearest_forum_posts = get_forum_posts(query + image_caption)
    puts nearest_forum_posts

    messages = [
      { "type": "text", "text": nearest_course_materials + nearest_forum_posts + " query: " + query + image_caption },
    ]

    response = OPENAI_CLIENT.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          { "role": "system", "content": @@llm_system_message },
          {
            role: "user",
            content: messages,
          },
        ],
      },
    )
    response.dig("choices", 0, "message", "content")
  end

  # Below code uses openai assistant
  # def self.get_response(query, file = nil)
  #   image_caption = ""
  #   if file
  #     image_caption = "Attached Image caption: #{self.get_image_caption(file)}"
  #   end
  #   assistant = OPENAI_CLIENT.assistants.create(
  #     parameters: {
  #       name: "AI RAG Forum Teaching Assistant",
  #       model: "gpt-4o",
  #       instructions: @@llm_system_message,
  #       tools: [
  #         {
  #           "type": "function",
  #           "function": {
  #             "name": "get_forum_posts",
  #             "description": "Gets the top k semantically nearest forum posts based on user query",
  #           },
  #         },
  #         {
  #           "type": "function",
  #           "function": {
  #             "name": "get_course_materials",
  #             "description": "Gets the top k semantically nearest chunk of course materials based on user query",
  #           },
  #         },
  #         {
  #           "type": "function",
  #           "function": {
  #             "name": "get_time",
  #             "description": "Gets the current time",
  #           },
  #         },
  #       ],
  #     },
  #   )

  #   assistant_id = assistant["id"]

  #   # Thread Creation
  #   thread = OPENAI_CLIENT.threads.create

  #   thread_id = thread["id"]

  #   OPENAI_CLIENT.messages.create(
  #     thread_id: thread_id,
  #     parameters: {
  #       role: "user",
  #       content: query + image_caption,
  #     },
  #   )["id"]

  #   # Run will submit thread created above
  #   run = OPENAI_CLIENT.runs.create(
  #     thread_id: thread_id,
  #     parameters: {
  #       assistant_id: assistant_id,
  #       max_prompt_tokens: 2000,
  #       max_completion_tokens: 4096,
  #     },
  #   )

  #   run_id = run["id"]

  #   # waits for run's status
  #   while true
  #     response = OPENAI_CLIENT.runs.retrieve(id: run_id, thread_id: thread_id)
  #     status = response["status"]
  #     case status
  #     when "queued", "in_progress", "cancelling"
  #       puts "Sleeping"
  #       sleep 1 # Wait one second and poll again
  #     when "completed"
  #       break # Exit loop and report result to user
  #     when "requires_action"
  #       tools_to_call = response.dig("required_action", "submit_tool_outputs", "tool_calls")
  #       puts "HERE"
  #       puts response
  #       my_tool_outputs = tools_to_call.map { |tool|
  #         # Call the functions based on the tool's name
  #         function_name = tool.dig("function", "name")
  #         arguments = JSON.parse(
  #           tool.dig("function", "arguments"),
  #           { symbolize_names: true },
  #         )
  #         tool_output = case function_name
  #           when "get_forum_posts"
  #             get_forum_posts(query)
  #           when "get_course_materials"
  #             get_course_materials(query)
  #           end

  #         { tool_call_id: tool["id"], output: tool_output }
  #       }
  #       puts my_tool_outputs
  #       OPENAI_CLIENT.runs.submit_tool_outputs(thread_id: thread_id, run_id: run_id, parameters: { tool_outputs: my_tool_outputs })
  #     when "cancelled", "failed", "expired"
  #       puts response["last_error"].inspect
  #       break # or `exit`
  #     else
  #       puts "Unknown status response: #{status}"
  #       break
  #     end
  #   end

  #   # extracting messages
  #   messages = OPENAI_CLIENT.messages.list(thread_id: thread_id, parameters: { order: "asc" })
  #   puts messages
  #   latest_response = messages["data"][-1]["content"][0]["text"]["value"]
  #   latest_response
  # end

  def self.generate_embedding(text)
    response = OPENAI_CLIENT.embeddings(
      parameters: {
        model: "text-embedding-ada-002",
        input: text,
      },
    )
    response["data"][0]["embedding"]
  end

  def self.get_forum_posts(query)
    query_embedding = generate_embedding(query)
    data = ForumData.get_nearest_neighbours(query_embedding).to_s
    data = "Below are a list of search results from the forum posts knowledge base:" + data
    data
  end

  def self.get_course_materials(query)
    query_embedding = generate_embedding(query)
    data = CourseMaterial.get_nearest_neighbours(query_embedding).to_s
    data = "Below are a list of search results from the course material knowledge base:" + data
  end
end
