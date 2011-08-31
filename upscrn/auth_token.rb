#
#  auth_token.rb
#  upscrn
#
#  Created by Matthew Cowley on 8/27/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#

class AuthToken
    def initialize
        #@config = Properties.new
        #begin
        #    @config.load(FileInputStream.new('config.properties'))
        #    rescue
        #end
    end
    
    def get_token
        #token = @config.get_property('token')
        #return token
        'mytoken'
    end
    
end
