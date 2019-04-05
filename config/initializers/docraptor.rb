DocRaptor.configure do |dr|
  dr.username = ENV['DOCRAPTOR_API_KEY'] || "WQKHqizgFsF0qdgHOOhf"
  dr.debugging = ENV['DOCRAPTOR_DEBUG'] || true
end
