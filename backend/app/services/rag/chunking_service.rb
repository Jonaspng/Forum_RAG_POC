require "base64"

class Rag::ChunkingService
  def initialize(text: nil, file: nil)
    raise ArgumentError, "Either text or file must be provided" if text.nil? && file.nil?
    if file
      @file = file
      @file_type = File.extname(file.original_filename).downcase
    else
      @text = text.gsub(/\s+/, " ").strip
    end
  end

  def file_chunking(image_option)
    if @file_type == ".pdf"
      reader = PDF::Reader.new(@file.path)
      if image_option
        text = extract_page_content_with_images.join("")
      else
        text = reader.pages.map(&:text).join(" ")
      end
    elsif @file_type == ".txt"
      text = File.read(@file.path)
    else
      raise "Unsupported file type: #{@file_type}"
    end

    @text = text.gsub(/\s+/, " ").strip
    fixed_size_chunk_text(500, 100)
  end

  def text_chunking
    fixed_size_chunk_text(500, 100)
  end

  private

  def extract_page_content_with_images
    chunks = []

    @reader.pages.each_with_index do |page, index|
      if page.xobjects.any? { |_, xobject| xobject.hash[:Subtype] == :Image }
        chunk = extract_images(index + 1)
      else
        chunk = page.text
        puts chunk
      end
      chunks << chunk
    end
    chunks
  end

  def extract_images(page_number)
    temp_dir = Dir.mktmpdir
    Docsplit.extract_images(@file_path, density: 300, pages: [page_number], format: :png, output: temp_dir)
    image_data = File.read(Dir.glob("#{temp_dir}/*.{png,jpg,jpeg,tiff}").first)
    slide_caption = Rag::LlmService.get_image_caption(image_data)
    FileUtils.remove_entry temp_dir
    slide_caption
  end

  def fixed_size_chunk_text(chunk_size, overlap_size)
    chunks = []
    start = 0
    ending = 0

    while ending < @text.length
      # Define the chunk with overlap
      chunk = @text[start, chunk_size]
      chunks << chunk

      ending = start + chunk_size
      # Move the starting position forward, keeping the overlap
      start += (chunk_size - overlap_size)
    end

    chunks
  end
end
