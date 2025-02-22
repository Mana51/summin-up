require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection


class User < ActiveRecord::Base
    has_secure_password
end 


class Summary < ActiveRecord::Base
    belongs_to :post
end


class Length < ActiveRecord::Base
    
end

class Difficulty < ActiveRecord::Base
    
end

class Post < ActiveRecord::Base
    
    def to_json(options = {})
    {
      id: id,
      content: content,
      keyword: keyword,
      difficulty_id: difficulty_id,
      length_id: length_id
    }.to_json(options)
    end
  
    has_many :summaries
    belongs_to :length
    belongs_to :difficulty
end

class Like < ActiveRecord::Base
    
end
