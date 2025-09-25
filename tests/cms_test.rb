ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"
require "rack/test"

require_relative "../cms"

Minitest::Reporters.use!

class CMSTest < Minitest::Test
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end

  # ==================
  # Setup tasks

  def setup
    @root = File.expand_path("../..", __FILE__)

    @files = Dir.glob(@root + "/data/*").map { |path| File.basename(path) }
  end
  
  # ===================
  # Tests

  def test_index
    get "/"

    assert_equal 200, last_response.status

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    
    @files.each do |filename|
      assert_includes last_response.body, filename
    end
  end

  def test_file_pages
    get "/history.txt"

    assert_equal 200, last_response.status

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    content = File.read(@root + "/data/history.txt").split("\n")
    assert_includes last_response.body, content.first
    assert_includes last_response.body, content.last
  end
end