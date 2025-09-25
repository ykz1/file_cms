require "sinatra"
require "sinatra/reloader" # if development?
require "tilt/erubi"

# =======================
# Helper methods

def root
  File.expand_path("..", __FILE__)
end

def filepath(filename)
  "/data/#{filename}"
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

not_found do
  redirect "/"
end

get "/" do
  erb :index
end

get "/:filename" do
  filename = params[:filename]
  if @files.include?(filename)
    @content = File.read(root + filepath(filename)).split("\n")

    erb :file
  else
    session[:error] = "File not found."

    redirect "/"
  end
end