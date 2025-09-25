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

  def test_file_not_found
    get "/nonexistent_file.png"

    # Test that page is redirecting
    assert_equal 302, last_response.status

    # Follow redirect path
    get last_response["Location"]

    # Test successful request
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]


    # Test error message is present
    assert_includes last_response.body, "nonexistent_file.png not found"

    # Reload page
    get "/"
    refute_includes last_response.body, "nonexistent_file.png not found"

  end

  def test_markdown_rendering
    get "/about.md"

    assert_equal 200, last_response.status

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "<h1>About Ruby</h1>"
  end

  def test_edit_page
    get "/test.txt/edit"

    assert_equal 200, last_response.status

    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, "<button type=\"submit\""
  end

  def test_edit_submission
    post "/test.txt/edit", edited_text: 'New text'

    assert_equal 302, last_response.status

    # Test success message shows up and then goes away
    get last_response["Location"]
    
    assert_includes last_response.body, "test.txt has been updated."

    get '/'

    refute_includes last_response.body, "test.txt has been updated."

    # Test that edited page has updated text
    get "/test.txt"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "New text"

  end
end
