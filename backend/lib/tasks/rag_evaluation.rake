# lib/tasks/rag_evaluation.rake
require "langchain"
namespace :rag do
  desc "Evaluate RAG workflow"
  task evaluate: :environment do
    # Place your RAG evaluation logic here
    puts "Starting RAG Evaluation..."
    File.open("lib/tasks/score.txt", "w") do |file|
      # Dont write anything to reset file
    end

    questions_list = JSON.parse(File.read("lib/tasks/questions.json"))

    models = ["Fixed Size Chunking retrieval", "HyDE Retrieval"]

    for model in models
      for question in questions_list
        evaluation_service = Rag::ResponseEvaluationService.new
        llm_service = Rag::LlmLangchainService.new(evaluation_service)

        if model == "Fixed Size Chunking retrieval"
          llm_service.get_response(question)
        else
          llm_service.get_response_hyde(question)
        end
        score = evaluation_service.evaluate
        File.open("lib/tasks/score.txt", "a") do |file|
          file.write(model + "\n")
          file.write(question + "\n")
          file.write(score.to_s + "\n")
        end
      end
    end
  end
end
