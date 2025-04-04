class Rag::Tools::CourseMaterialsTool
  extend Langchain::ToolDefinition

  define_function :get_course_materials, description: "CourseMaterialsTool: Retrieve the course material chunks that are
   semantically closest to the user query. It will also inform user if requested course material is not found." do
    property :user_query, type: "string", description: "exact user query", required: true
    property :course_material_name, type: "string", description: "name of course material in user query", required: false
  end

  def initialize(evaluation)
    @client = LANGCHAIN_OPENAI
    @evaluation = evaluation
  end

  def get_course_materials(user_query:, course_material_name: nil)
    query_embedding = @client.embed(text: user_query, model: "text-embedding-ada-002").embedding
    if course_material_name
      materials_list = CourseMaterial.get_course_materials_list.to_s
      messages = [
        { role: "system", content: Langchain::Prompt.load_from_path(file_path: "app/services/rag/prompts/guess_course_material_name_system_prompt_template.json").format },
        { role: "user", content: "Actual Course Materials List: " + materials_list + " user query: " + course_material_name }
      ]
      actual_course_material_name = JSON.parse(LANGCHAIN_OPENAI.chat(messages: messages, temperature: 0).chat_completion)
      if actual_course_material_name != "NOT FOUND"
        data = "Below are a list of search results from the course materials knowledge base:" + CourseMaterial.get_nearest_neighbours(query_embedding, file_name: actual_course_material_name).to_s
      else
        data = CourseMaterial.get_nearest_neighbours(query_embedding).to_s
        data = "MUST ALWAYS Inform user that #{course_material_name} course material requested does not exist. Proceeding to search from other course materials: " + data
      end
    else
      data = "Below are a list of search results from the course materials knowledge base:" + CourseMaterial.get_nearest_neighbours(query_embedding).to_s
    end
    # append to context for evaluation service
    @evaluation.context += data
    puts data
    data
  end
end
