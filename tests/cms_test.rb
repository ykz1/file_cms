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

  def session
    last_request.env["rack.session"]
  end

  def auth_get(path)
    get path, {}, {"rack.session" => {user: "admin"} }
  end

  def auth_post(path, params = {} )
    post path, params, {"rack.session" => {user: "admin" } }
  end


  def test_index
    create_document "about.md"
    create_document "changes.txt"

    auth_get "/"

    assert_equal 200, last_response.status

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_file_pages
    create_document "history.txt"

    auth_get "/history.txt"

    assert_equal 200, last_response.status

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  end

  def test_file_not_found
    auth_get "/nonexistent_file.png"

    # Test that page is redirecting
    assert_equal 302, last_response.status
    assert_equal "nonexistent_file.png not found.", session[:message]
  end

  def test_markdown_rendering
    create_document "about.md", "# Title"

    auth_get "/about.md"

    assert_equal 200, last_response.status

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "<h1>Title</h1>"
  end

  def test_edit_page
    create_document "test.txt"

    auth_get "/test.txt/edit"

    assert_equal 200, last_response.status

    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, "<button type=\"submit\""
  end

  def test_edit_submission
    create_document "test.txt"

    auth_post "/test.txt/edit", edited_text: 'New text'

    assert_equal 302, last_response.status
    assert_equal "test.txt has been updated.", session[:message]

    # Test that edited page has updated text
    auth_get "/test.txt"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "New text"
  end

  def test_new_file_happy_path
    # Test that link to create new file exists on index
    auth_get "/"
    assert_includes last_response.body, "New File"
    assert_includes last_response.body, %Q(="/new")

    # Test that new file creation page loads properly and contains input field + button to submit
    auth_get "/new"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %Q(<button type="submit")
    assert_includes last_response.body, "<input"

    # Test that submitting a valid file name creates new file
    auth_post "/new", file_name: "new_file.txt"
    assert_equal 302, last_response.status
    assert_equal "new_file.txt has been created.", session[:message]

    auth_get "/"
    assert_includes last_response.body, "new_file.txt"
    
    # Test that individual page for new file exists and loads
    auth_get "/new_file.txt"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  end
  
  def test_new_file_invalid_name
    # Test blank entry
    auth_post "/new", file_name: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Name must be between 1 and 100 characters."

    # Test invalid extensions
    auth_post "/new", file_name: "test.exe"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "File extension must be one of"
    
    # Test existing filename + entered value retained
    create_document "name.txt"
    auth_post "/new", file_name: "name.txt"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "File already exists."
    assert_includes last_response.body, %Q(value="name.txt")
    
    # Test trailing and leading spaces are removed
    auth_post "/new", file_name: "        new_file.txt    "
    assert_equal 302, last_response.status
    auth_get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new_file.txt has been created."
    assert_includes last_response.body, %Q(<a href="new_file.txt">)
    auth_get "/"
    refute_includes last_response.body, "new_file.txt has been created."
  end

  def test_delete_file
    create_document "test.txt"
    
    auth_post "/test.txt/delete"
    assert_equal 302, last_response.status
    assert_equal "test.txt has been deleted.", session[:message]
    
    auth_get "/"
    refute_includes last_response.body, %q(a href="test.txt")
  end

  def test_login
    # Test that wrong credentials result in no login
    post "/users/login", username: "notadmin", password: "notsecret"
    assert_equal 422, last_response.status
    assert_nil session[:user]
    assert_includes last_response.body, "Invalid credentials."

    post "/users/login", username: "admin", password: "notsecret"
    assert_includes last_response.body, "Invalid credentials"
    
    # Test that correct credentials logs user in
    post "/users/login", username: "admin", password: "secret"
    assert_equal 302, last_response.status
    
    auth_get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Welcome"
    assert_includes last_response.body, "Logged in as admin"
  end

  def test_restricted_access
    create_document "about.md"

    get '/'
    refute_includes last_response.body, "about.md"

    get '/about.md'
    assert_equal 302, last_response.status
    assert_equal "Sign in to view and edit files.", session[:message]
    refute_includes last_response.body, "about.md"

    get '/about.md/edit'
    assert_equal 302, last_response.status
    assert_equal "Sign in to view and edit files.", session[:message]
    refute_includes last_response.body, "about.md"

    post '/about.md/edit', edited_text: "New text"
    assert_equal 302, last_response.status
    assert_equal "Sign in to view and edit files.", session[:message]
    refute_includes last_response.body, "about.md"
    get '/about.md'
    refute_includes last_response.body, "New text"

    get '/new'
    assert_equal 302, last_response.status
    assert_equal "Sign in to view and edit files.", session[:message]

    post '/new', file_name: "new_file.txt"
    assert_equal 302, last_response.status
    assert_equal "Sign in to view and edit files.", session[:message]
    auth_get '/'
    refute_includes last_response.body, "new_file.txt"
  end

  def test_restricted_delete
    create_document "about.md"

    post "/about.md/delete"
    assert_equal 302, last_response.status
    assert_equal "Sign in to view and edit files.", session[:message]
    auth_get '/'
    assert_includes last_response.body, "about.md"
  end
end
