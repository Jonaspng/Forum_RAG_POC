require "base64"

class Rag::ChunkingService
  def self.initialize(file)
    @pdf_path = file.path
    @filename = file.original_filename
    @reader = PDF::Reader.new(@pdf_path)
  end

  def self.slide_chunking
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

  def self.fixed_size_chunking(image_option)
    if image_option == "true"
      text = slide_chunking.join("")
    else
      text = @reader.pages.map(&:text).join(" ")
    end
    text = text.gsub(/\s+/, " ").strip
    chunks = chunk_text(text, 500, 100)

    self.insert_chunks_to_db(chunks)
  end

  def self.extract_images(page_number)
    temp_dir = Dir.mktmpdir
    Docsplit.extract_images(@pdf_path, density: 300, pages: [page_number], format: :png, output: temp_dir)
    image_data = File.read(Dir.glob("#{temp_dir}/*.{png,jpg,jpeg,tiff}").first)
    slide_caption = Rag::LlmService.get_image_caption(image_data)
    FileUtils.remove_entry temp_dir
    slide_caption
  end

  def self.chunk_text(text, chunk_size, overlap_size)
    chunks = []
    start = 0

    while start < text.length
      # Define the chunk with overlap
      chunk = text[start, chunk_size]
      chunks << chunk

      # Move the starting position forward, keeping the overlap
      start += (chunk_size - overlap_size)
    end

    chunks
  end

  def self.insert_chunks_to_db(chunks)
    for chunk in chunks
      embedding = Rag::LlmService.generate_embedding(chunk)
      CourseMaterial.create(embedding: embedding, data: chunk, file_name: @filename)
    end
  end
end
