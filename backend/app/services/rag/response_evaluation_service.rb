class Rag::ResponseEvaluationService
  attr_accessor :context, :question, :answer

  def initialize()
    @ragas = Langchain::Evals::Ragas::Main.new(llm: RAGAS)
    @context = ""
    @question = ""
    @answer = ""
  end

  def evaluate
    @ragas.score(answer: @answer, question: @question, context: @context)
  end
end
