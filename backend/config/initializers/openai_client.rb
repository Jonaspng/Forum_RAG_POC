# Check if OPENAI_API_KEY is set
if ENV["OPENAI_API_KEY"].present?
  require "openai"
  # Create a global OpenAI client instance
  OPENAI_CLIENT = OpenAI::Client.new(
    access_token: ENV["OPENAI_API_KEY"],
    log_errors: true
  )
else
  Rails.logger.error("OPENAI_API_KEY is not set in the environment")
end
