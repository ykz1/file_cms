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