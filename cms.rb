require "redcarpet"
require "sinatra"
require "sinatra/reloader" # if development?
require "tilt/erubi"

# =======================
# Helper methods
def data_path
  if ENV["RACK_ENV"] == "test"
    return "#{root_path}/tests/data"
  else
    return "#{root_path}/data"
  end
end

def root_path
  File.expand_path("..", __FILE__)
end

def file_path(filename)
  "#{data_path}/#{filename}"
end

def read_file_plain(filename)
  File.read(file_path(filename))
end

def render_file(filename)
  content = read_file_plain(filename)

  if filename[-3, 3] == '.md'
    return render_from_markdown(content)
  else
    return render_from_plain(content)
  end
end

def render_from_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  return markdown.render(text)
end

def render_from_plain(text)
  text.split("\n").map do |paragraph|
    "<p>#{paragraph}</p>"
  end.join
end

def check_name_error(filename)
  return "Name must be between 1 and 100 characters." if !(1..100).cover? filename.size

  return "File already exists." if @files.include? filename

  return "File extension must be one of: #{valid_extensions.join(", ")}." unless valid_extension?(filename)

  nil
end

def valid_extensions
  [".txt", ".md"]
end

def valid_extension?(filename)
  valid_extensions.any? do |extension|
    length = extension.length
    filename[-length, length] == extension
  end
end


# =======================
# Before and configure

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  @files = Dir.glob("#{data_path}/*").map { |path| File.basename(path) }
end

# =======================
# View helpers

helpers do
  
end

# =======================
# Routes

# Bad URLs redirect to home
not_found do
  redirect "/"
end

# Home / index page
get "/" do
  erb :index
end

# Login page
get "/users/login" do
  if session[:user]
    redirect "/"
  else
    erb :login
  end
end

def authenticate?(username, password)
  username == "admin" && password == "secret"
end

post "/users/login" do
  username = params[:username].strip.downcase
  password = params[:password]

  if authenticate?(username, password)
    session[:user] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials."
    status 422
    erb :login
  end
end

post "/users/logout" do
  session.delete(:user)
  session[:message] = "You have been signed out"
  redirect "/"
end

# New file creation page
get "/new" do
  erb :file_new
end

# New file creation post
post "/new" do
  filename = params[:file_name].strip

  error_message = check_name_error(filename)

  if error_message
    session[:message] = error_message
    status 422
    erb :file_new
  else
    File.write(file_path(filename), '')
    session[:message] = "#{filename} has been created."
    redirect "/"
  end
end

# File edit pages: display edit page
get "/:filename/edit" do
  filename = params[:filename]

  if @files.include?(filename)
    @content = read_file_plain(filename)
    
    erb :file_edit
  else
    session[:message] = "#{filename} not found."

    redirect "/"
  end
end

# File edit pages: save edits
post "/:filename/edit" do
  filename = params[:filename]
  new_content = params[:edited_text]

  # Sanitize input
  # Add validations 

  File.write(file_path(filename), new_content)

  session[:message] = "#{filename} has been updated."

  redirect '/'
end

# Delete pages
post "/:filename/delete" do
  File.delete(file_path(params[:filename]))
  status 303

  session[:message] = "#{params[:filename]} has been deleted."

  redirect '/'
end

# File pages
get "/:filename" do
  filename = params[:filename]
  if @files.include?(filename)
    @content = render_file(filename)

    erb :file
  else
    session[:message] = "#{filename} not found."

    redirect "/"
  end
end