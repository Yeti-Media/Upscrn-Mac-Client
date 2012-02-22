#
#  upscrn_client.rb
#  upscrn
#
#  Created by Matthew Cowley on 8/27/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#


#$LOAD_PATH << 'lib/ruby/json/lib'
require 'json'
require 'rubygems'
#require 'json/lib/json.rb'
require 'rest-client'

class UpscrnClient
    class << self
        def projects
          Logger.debug "getting projects.."
          token = $defaults[$token_key]
          projects = UpscrnClient.perform('get', 'projects', token)
          projects
        end
    
        def upload_screenshot(filename,project_id=nil)
           filepath = NSHomeDirectory().stringByAppendingPathComponent("Desktop/#{filename}")
            Logger.debug "filepath: #{filepath}"
            @result = Hash.new
            @result['success'] = true
            file = File.open filepath, 'r'
            token = $defaults[$token_key]
            Logger.debug "about to grab; token= #{token}"
            begin
                if project_id
                    
                    post_response = UpscrnClient.perform("post", "projects/#{project_id}/screenshots", token,  {:screenshot => {:image => file}})
                else
                    post_response = UpscrnClient.perform('post', 'screenshots', token, {:screenshot => {:image => file}})
                    
                    #post_response = UpscrnClient.perform('post', 'screenshots', {:image => @image, :auth_token => token})
                end
                
                Logger.debug "response: #{post_response}"
                @url = post_response["url"]
                @result['success'] = true
                @result['url'] = @url
                #clickable_link = NSAttributedString.hyperlinkFromString("See on upscrn", withURL:nsurl)
                Logger.debug "url = #{@url}"
                #@url_label.stringValue = nsurl
                #show_screenshot_url(@url, nsurl)
                @url
            rescue Exception => e
                Logger.debug "Exception!  #{e.message}"
                @result['success'] = false
                Logger.debug "1"
                @result['error'] = e.message.to_s
                Logger.debug "set result"
                #@url_label.stringValue = e.message
            end
            @result
        end
    
    def perform(verb,action,auth_token, params={})
        action = [action, 'json'].join('.')
        url = ['http://upscrn.com', action].join('/')
        #      url = ['http://127.0.0.1:3000', action].join('/')
        url = url + "?auth_token=#{auth_token}"
        Logger.debug url
        JSON.parse(RestClient.send(verb,url,params).body)
    end
    end
end

