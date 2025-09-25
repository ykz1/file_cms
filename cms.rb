require "redcarpet"
require "sinatra"
require "sinatra/reloader" # if development?
require "tilt/erubi"

# =======================
# Helper methods
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def root
  File.expand_path("..", __FILE__)
end

def filepath(filename)
  "#{root}/data/#{filename}"
end

def read_file_plain(filename)
  File.read(filepath(filename))
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
# Before

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  @files = Dir.glob(root + "/data/*").map { |path| File.basename(path) }
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

  File.write(filepath(filename), new_content)

  session[:message] = "#{filename} has been updated."

  redirect '/'
end