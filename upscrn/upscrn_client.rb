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
    
    
        def upload_screenshot(filename)
           filepath = NSHomeDirectory().stringByAppendingPathComponent("Desktop/#{filename}")
            puts "filepath: #{filepath}"
            @result = Hash.new
            @result['success'] = true
            file = File.open filepath, 'r'
            token = $defaults[$token_key]
            puts "about to grab; token= #{token}"
            upload_to_project = false
            begin
                if upload_to_project
                    
                    post_response = UpscrnClient.perform("post", "projects/#{project}/screenshots", token,  {:screenshot => {:image => @image}})
                    else
                    post_response = UpscrnClient.perform('post', 'screenshots', token, {:screenshot => {:image => file}})
                    
                    #post_response = UpscrnClient.perform('post', 'screenshots', {:image => @image, :auth_token => token})
                end
                
                puts "response: #{post_response}"
                @url = post_response["url"]
                @result['success'] = true
                @result['url'] = @url
                #clickable_link = NSAttributedString.hyperlinkFromString("See on upscrn", withURL:nsurl)
                puts "url = #{@url}"
                #@url_label.stringValue = nsurl
                #show_screenshot_url(@url, nsurl)
                @url
            rescue Exception => e
                puts "Exception!  #{e.message}"
                @result['success'] = false
                puts "1"
                @result['error'] = e.message.to_s
                puts "set result"
                #@url_label.stringValue = e.message
            end
            @result
        end
    
        def perform(verb,action,auth_token, params={})
            action = [action, 'json'].join('.')
            url = ['http://upscrn.com', action].join('/')
            #url = ['http://127.0.0.1:3000', action].join('/')
            url = url + "?auth_token=#{auth_token}"
            puts "url: #{url} params: #{params}"
            JSON.parse(RestClient.send(verb,url,params).body)
        end
    end
end

