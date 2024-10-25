class QueriesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create

    query = params[:query]
    file = params[:file]

    evaluation_service = Rag::ResponseEvaluationService.new
    rag_workflow = Rag::RagWorkflowService.new(evaluation_service)

    final_response = rag_workflow.get_assistant_response(query, file)

    # evaluation score
    evaluation_result = evaluation_service.evaluate
    puts evaluation_service.context

    # Step 4: Send the final response back to the frontend
    render json: { response: final_response, evaluation: evaluation_result }
  end
end
