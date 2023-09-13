require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models.rb'
require "pry"
require 'sidekiq'
require 'sidekiq/api'
require 'redis'
require 'zlib'


# require 'httparty'
# client = OpenAI::Client.new(access_token: "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")

client = OpenAI::Client.new(access_token: "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")

configure do
  logger = Logger.new('sinatra.log')
  
  logger.formatter = proc do |severity, datetime, progname, msg|
    "#{datetime}: #{msg}\n"
  end

  logger.level = Logger::DEBUG

  set :logger, logger
end

enable :sessions

get '/' do
  erb :sign_in
end


get '/signin' do
    erb :sign_in
end

get '/signup' do
    erb :sign_up
end

post '/signin' do
    user = User.find_by(username: params[:username])
    if user && user.authenticate(params[:password])
        session[:user] = user.id
        redirect '/home'
    else
        redirect '/signin'
    end 
end

post '/signup' do
    user = User.create(username: params[:username], password: params[:password], password_confirmation: params[:password_confirmation])
    if user.persisted?
        session[:user] = user.id
        redirect '/home'
    else 
        redirect '/signup'
    end 

end 

get '/signout' do
    session[:user] = nil
    redirect '/'
end 


get '/home' do
    @posts = Post.all.sort.reverse
    @page = "home"
    erb :home
end


get '/filter' do
    erb :filter
end

post '/filter' do
  result = Post.where(keyword: params[:keyword], difficulty_id: params[:difficulty], length_id: params[:length]).sort.reverse
  compressed_data = Zlib::Deflate.deflate(result.to_json)  # Serialize as JSON
  session[:matches] = compressed_data
  redirect '/filtered'
end

get '/filtered' do
  @page = "filtered"
  decompressed_data = Zlib::Inflate.inflate(session[:matches])
  @matches = JSON.parse(decompressed_data)  # Deserialize from JSON
  erb :filtered
end


get '/home/:id' do
    @user = session[:user]
    @id = params[:id]
    @post = Post.find_by(id: params[:id])
    post_id = @post.id
    session[:post_id] = post_id
    summaries = Summary.all
    @postedSummary = []
    @userSummary= []
    summaries.each do |sum|
        if sum.post_id == post_id
            likesNum = Like.where(summary_id: sum.id).count
            if sum.user_id == @user
                @userSummary.append(sum)
            else 
                @postedSummary.append(sum)
            end
        end
    end
    @userSummary = @userSummary.sort_by { |sum| -Like.where(summary_id: sum.id).count }
    @postedSummary = @postedSummary.sort_by { |sum| -Like.where(summary_id: sum.id).count }
    erb :displayPosts
end

get '/generate' do
    erb :generate
end


post '/generate' do
    len = Length.find_by(id: params[:length])
    dif = Difficulty.find_by(id: params[:difficulty])
    length = len.length
    difficulty = dif.difficulty
    prompt = "Generate an article related to #{params[:keyword]} in #{length} words, with a vocabulary difficulty level of #{difficulty} out of 5."
    client = OpenAI::Client.new
    create_text = nil
    Thread.new do  
        response = client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: [{ role: "user", content: prompt }],
            temperature: 0.9
        })
        create_text = response.dig("choices", 0, "message", "content")
    end.join 
    
    result = create_text.gsub("\n", "<br>") 
    compressed_data = Zlib::Deflate.deflate(result)
    
    
    session[:formatted_text] = compressed_data
    session[:keyword] = params[:keyword]
    session[:length] = length
    session[:difficulty] = difficulty
    
    
    redirect '/create_post'
end



get '/create_post' do
    decompressed_data = Zlib::Inflate.inflate(session[:formatted_text])
    
    @keyword = session[:keyword]
    @length = session[:length]
    @difficulty = session[:difficulty]
    @formatted_text = decompressed_data 
    
    @summaries = Summary.all
    
    erb :post
end


post '/post' do
    length_id = Length.find_by(length: session[:length]).id
    difficulty_id = Difficulty.find_by(difficulty: session[:difficulty]).id
    content = Zlib::Inflate.inflate(session[:formatted_text])
    nowPost = Post.create(
        content: content,
        keyword: session[:keyword],
        difficulty_id: difficulty_id,
        length_id: length_id
    )
    
    session.delete(:formatted_text)
    session.delete(:keyword)
    session.delete(:difficulty)
    
    session[:post_id] = nowPost.id
    
    Summary.create(
        post_id: nowPost.id, 
        user_id: session[:user], 
        title: params[:title], 
        summary: params[:summary]
    )
    redirect '/display_posts'
end

get '/display_posts' do
    @post = Post.find_by(id: session[:post_id])
    summaries = Summary.all
    s_id = Summary.ids
    @userSummary= []
    @postedSummary = []
    @user = session[:user]
    summaries.each do |sum|
        if sum.post_id == @post.id
            likesNum = Like.where(summary_id: sum.id).count
            if sum.user_id == @user
                @userSummary.append(sum)
            else 
                @postedSummary.append(sum)
            end
        end
    end
    @userSummary = @userSummary.sort_by { |sum| -Like.where(summary_id: sum.id).count }
    @postedSummary = @postedSummary.sort_by { |sum| -Like.where(summary_id: sum.id).count }
    erb :displayPosts
end

get '/new-summary/:id' do
    post_id = params[:id]
    session[:post_id] = post_id
    @post = Post.find_by(id: post_id)
    dif = Difficulty.find_by(id: @post.difficulty_id).difficulty
    len = Length.find_by(id: @post.length_id).length
    @keyword = @post.keyword
    @difficulty = dif
    @length = len
    @formatted_text = @post.content
    erb :newSummary
end

post '/new-summary' do
    # @postedSummary = Summary.all
    post_id = session[:post_id]
    @post = Post.find_by(id: session[:post_id])
    Summary.create(
        post_id: post_id, 
        user_id: session[:user], 
        title: params[:title], 
        summary: params[:summary]
    )
    redirect '/posted'
end

get '/posted' do
    @user = session[:user]
    id = session[:post_id]
    @post = Post.find_by(id: id)
    post_id = @post.id
    session[:post_id] = post_id
    summaries = Summary.all
    @userSummary= []
    @postedSummary = []
    summaries.each do |sum|
        if sum.post_id == post_id
            likesNum = Like.where(summary_id: sum.id).count
            if sum.user_id == @user
                @userSummary.append(sum)
            else 
                @postedSummary.append(sum)
            end
        end
    end
    @userSummary = @userSummary.sort_by { |sum| -Like.where(summary_id: sum.id).count }
    @postedSummary = @postedSummary.sort_by { |sum| -Like.where(summary_id: sum.id).count }
    erb :displayPosts
end

post '/likes/:id' do
    summary_id = params[:id]
    liked = Like.find_by(summary_id: summary_id, user_id: session[:user])
    if liked.nil?
        Like.create(user_id: session[:user], summary_id: summary_id)
    else
        liked.destroy
    end
    redirect '/display_posts'
    
end

get '/summary/:id/edit' do
    @summary = Summary.find(params[:id])
    @post = Post.find_by(id: @summary.post_id)
    @length = Length.find_by(id: @post.length_id)
    erb :edit
end

post '/edit-summary/:id' do
    summary = Summary.find(params[:id])
    summary.title = params[:title]
    summary.summary = params[:summary]
    summary.save
    redirect '/display_posts'
end

post '/summary/:id/delete' do
    summary = Summary.find(params[:id])
    summary.destroy
    redirect '/display_posts'
end
