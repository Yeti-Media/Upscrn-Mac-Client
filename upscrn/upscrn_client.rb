#
#  upscrn_client.rb
#  upscrn
#
#  Created by Matthew Cowley on 8/27/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#


#$LOAD_PATH << 'lib/ruby/json/lib'
require 'rubygems'
require 'json/lib/json.rb'
require 'rest-client'

class UpscrnClient
    class << self
    
    def perform(verb,action,params={})
        action = [action, 'json'].join('.')
        url = ['http://upscrn.com', action].join('/')
        puts "url: #{url}"
        #      url = ['http://127.0.0.1:3000', action].join('/')
        JSON.parse(RestClient.send(verb,url,params).body)
    end
end
end

