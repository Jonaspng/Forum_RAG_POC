require "httparty"
require "json"
require "nokogiri"

class Rag::VideoCaptionService
  def initialize(video_url)
    @video_id = extract_video_id(video_url)
  end

  def fetch_title
    api_url = "https://www.googleapis.com/youtube/v3/videos?id=#{@video_id}&key=#{ENV["YOUTUBE_API_KEY"]}&part=snippet"

    # Make API request and handle potential errors
    begin
      response = HTTParty.get(api_url)
      if response.code != 200
        raise StandardError, "API Request failed with code: #{response.code}"
      end
    rescue HTTParty::Error => e
      raise StandardError, "Failed to connect to YouTube API: #{e.message}"
    end

    json_response = JSON.parse(response.body)

    # Check for video data in the API response
    if json_response["items"] && json_response["items"].any?
      video_title = json_response["items"][0]["snippet"]["title"]
    else
      raise StandardError, "Video not found for ID: #{@video_id}"
    end

    video_title
  end

  def fetch_captions
    api_url = "https://www.youtube.com/youtubei/v1/player?key=#{ENV["YOUTUBE_API_KEY"]}&prettyPrint=false"

    youtube_headers = {
      "Accept-Language" => "en-US,en;q=0.5",
      "Content-Type" => "application/json",
      "X-Youtube-Client-Name" => "1",
      "X-Youtube-Client-Version" => "2.20230607.06.00",
      "Sec-Fetch-Mode" => "no-cors",
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    }

    # Build the request body
    request_body = {
      context: {
        client: {
          hl: "en",
          clientName: "WEB",
          clientVersion: "2.20230607.06.00",
        },
      },
      videoId: @video_id,
      params: "",
    }.to_json

    # Make the POST request to YouTube API
    response = HTTParty.post(api_url, headers: youtube_headers, body: request_body)

    # Parse the response to find captions
    tracks = response.parsed_response.dig("captions", "playerCaptionsTracklistRenderer", "captionTracks")

    if tracks
      # Get captions in WebVTT format
      xml_captions = HTTParty.get(tracks.first["baseUrl"]).body
      xml_captions.gsub!("&amp;#39;", "'")
      xml_captions = Nokogiri::HTML::Document.parse(xml_captions)
      extracted_captions = xml_captions.xpath("//text").map(&:text).join(" ")
      extracted_captions
    end
  end

  private

  def extract_video_id(video_url)
    video_url.match(/(?:https?:\/\/)?(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})/)[1]
  end
end

# class CaptionsController < ApplicationController
#   def extract
#     video_url = params[:video_url] # Example of grabbing the video URL from the request
#     extractor = YouTubeCaptionsExtractor.new(video_url)
#     extractor.fetch_captions

#     render plain: "Captions extracted and saved!"
#   end
# end
