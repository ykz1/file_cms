require "redcarpet"
require "sinatra"
require "sinatra/reloader" # if development?
require "tilt/erubi"
require "yaml"
require "bcrypt"

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
  filename.end_with?(*valid_extensions)
end

def append_filename(original_name)
  extension = valid_extensions.find { |ext| original_name.end_with?(ext) }
  name = original_name.delete_suffix(extension)
  "#{name}_copy#{extension}"
end

def authenticate?(username, password)
  users = get_user_list
  return false unless users.key?(username)
  BCrypt::Password.new(users[username]) == password
end

def require_user_login
  unless session[:user]
    session[:message] = "Sign in to view and edit files."
    session[:redirect_to] = request.path_info
    redirect "/users/login"
  end
end

def admin_user?
  session[:user] == "admin"
end

def get_user_list
  if ENV["RACK_ENV"] == "test"
    return YAML.load_file("#{root_path}/tests/users.yml")
  else
    return YAML.load_file("#{root_path}/private/users.yml")
  end
end

def check_signup_entry(username, password, password_confirm)
  return "Passwords must match." unless password == password_confirm
  return "Username is taken." if get_user_list().key?(username)
  nil
end

def add_user(username, password)
  users = get_user_list()
  users[username] = BCrypt::Password.create(password).to_s
  save_to_user_list(users)
end

def save_to_user_list(users)
  if ENV["RACK_ENV"] == "test"
    File.write("#{root_path}/tests/users.yml", YAML.dump(users))
  else
    File.write("#{root_path}/private/users.yml", YAML.dump(users))
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

# Signup page
get "/users/signup" do
  if session[:user]
    redirect "/"
  else
    erb :signup
  end
end

post "/users/signup" do
  redirect "/" if session[:user]
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  error_message = check_signup_entry(username, password, password_confirm)
  
  if error_message
    session[:message] = error_message
    erb :signup
  else
    add_user(username, password)
    session[:user] = username
    session[:message] = "You are now registered, welcome!"
    redirect '/'
  end
end

# Login page
get "/users/login" do
  if session[:user]
    redirect "/"
  else
    erb :login
  end
end

post "/users/login" do
  redirect "/" if session[:user]

  username = params[:username].strip.downcase
  password = params[:password]

  if authenticate?(username, password)
    session[:user] = username
    session[:message] = "Welcome!"
    redirect session.delete(:redirect_to) || "/"
  else
    session[:message] = "Invalid credentials."
    status 422
    erb :login
  end
end

post "/users/logout" do
  if session.delete(:user)
    session[:message] = "You have been signed out"
  end
  
  redirect "/"
end

# New file creation page
get "/new" do
  require_user_login()

  erb :file_new
end

# New file creation post
post "/new" do
  require_user_login()

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
  require_user_login()

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
  require_user_login()

  filename = params[:filename]
  new_content = params[:edited_text]

  # Sanitize input
  # Add validations 

  File.write(file_path(filename), new_content)

  session[:message] = "#{filename} has been updated."

  redirect '/'
end

# Delete file
post "/:filename/delete" do
  require_user_login()

  File.delete(file_path(params[:filename]))
  status 303

  session[:message] = "#{params[:filename]} has been deleted."

  redirect '/'
end

# Duplicate a file
post "/:filename/duplicate" do
  require_user_login()

  filename = append_filename(params[:filename])
  content = File.read(file_path(params[:filename]))

  File.write(file_path(filename), content)
  session[:message] = "#{filename} created."
  redirect '/'
end

# File pages
get "/:filename" do
  require_user_login()

  filename = params[:filename]
  if @files.include?(filename)
    @content = render_file(filename)

    erb :file
  else
    session[:message] = "#{filename} not found."

    redirect "/"
  end
end

# User list
