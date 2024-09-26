class QueriesController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create
    query = params[:query]
    file = params[:file]

    final_response = Rag::LlmService.get_response(query, file)

    # Step 4: Send the final response back to the frontend
    render json: { response: final_response }
  end
end
