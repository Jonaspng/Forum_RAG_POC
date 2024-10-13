class QueriesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    query = params[:query]
    file = params[:file]

    evaluation_service = Rag::ResponseEvaluationService.new
    llm_service = Rag::LlmLangchainService.new(evaluation_service)

    final_response = llm_service.get_assistant_response(query, file)

    # evaluation score
    evaluation_result = evaluation_service.evaluate

    # Step 4: Send the final response back to the frontend
    render json: { response: final_response, evaluation: evaluation_result }
  end
end
