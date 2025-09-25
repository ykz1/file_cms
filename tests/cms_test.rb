ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"
require "rack/test"

require "fileutils"

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
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content="")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end
  
  # ===================
  # Tests

  def test_index
    create_document "about.md"
    create_document "changes.txt"

    get "/"

    assert_equal 200, last_response.status

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_file_pages
    create_document "history.txt"

    get "/history.txt"

    assert_equal 200, last_response.status

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
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
    create_document "about.md", "# Title"

    get "/about.md"

    assert_equal 200, last_response.status

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "<h1>Title</h1>"
  end

  def test_edit_page
    create_document "test.txt"

    get "/test.txt/edit"

    assert_equal 200, last_response.status

    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, "<button type=\"submit\""
  end

  def test_edit_submission
    create_document "test.txt"

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
