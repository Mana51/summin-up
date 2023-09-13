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
    has_many :summaries
    belongs_to :length
    belongs_to :difficulty
end

class Like < ActiveRecord::Base
    
end
