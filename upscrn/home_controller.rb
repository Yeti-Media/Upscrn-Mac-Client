#
#  home_controller.rb
#  upscrn
#
#  Created by Matthew Cowley on 8/30/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#


#
#  my_window_controller.rb
#  upscrn
#
#  Created by Matthew Cowley on 8/25/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#

require 'auth_token'
require 'upscrn_client'

class HomeController < NSWindowController
    attr_accessor :url_label
    
    @kCGWindowImageDefault = 0
    @kCGWindowListOptionAll = 0
    kCGWindowListOptionOnScreenOnly = 1
    kCGWindowListOptionOnScreenAboveWindow = (1 << 1)
    kCGWindowListOptionOnScreenBelowWindow = (1 << 2)
    kCGWindowListOptionIncludingWindow = (1 << 3)
    kCGWindowListExcludeDesktopElements = (1 << 4)
    
    @kCGWindowListOptionOnScreenOnly = (1<<4)
    @kCGNullWindowID = 0 #(CGWindowID)0
    
    #dummy action for testing quick things, from a button on the screen
    def testme(sender)
        nsurl = NSURL.URLWithString("http://cnn.com")   
        show_screenshot_url("http://cnn.com", nsurl)
    end
    def show_status(text)
        @url_label.stringValue = text
    end
    
    def grabScreenshot(sender)
        queue = Dispatch::Queue.new('com.yeti.upsrcrn.gcd')
        queue.async do
            show_status("Capturing image...")
        end
        queue.async do
        #@url_label.textDidChange(NSNotification.notificationWithName("dummy", sender ))
        puts "defaults token: #{$defaults.stringForKey($token_key)}"
        # This just invokes the API as you would if you wanted to grab a screen shot. The equivalent using the UI would be to
        # enable all windows, turn off "Fit Image Tightly", and then select all windows in the list.
        #StopwatchStart();
        kCGWindowImageDefault = 0
        kCGWindowListOptionAll = 0
        kCGWindowListOptionOnScreenOnly = 1
        #kCGWindowListOptionOnScreenAboveWindow = (1 << 1)
        #kCGWindowListOptionOnScreenBelowWindow = (1 << 2)
        #kCGWindowListOptionIncludingWindow = (1 << 3)
        #kCGWindowListExcludeDesktopElements = (1 << 4)
        
        #kCGWindowListOptionOnScreenOnly = (1<<4)
        kCGNullWindowID = 0 #(CGWindowID)0
        puts "cgrect: #{CGRectInfinite}"
        puts "options: #{kCGWindowListOptionOnScreenOnly}"
        puts "nullwindow: #{kCGNullWindowID}"
        puts "image def: #{kCGWindowImageDefault}"
        screenShot = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);
        #Profile(screenShot);
        #StopwatchEnd("Screenshot");
         uploadImage(screenShot);
        CGImageRelease(screenShot);
        end
    end
    
    def uploadImage(cgImage)
        status_message = "Uploading image..."
        @url_label.stringValue = status_message
        if cgImage != nil
            
            # Create a bitmap rep from the image...
            bitmapRep = NSBitmapImageRep.alloc.initWithCGImage(cgImage)
            # Create an NSImage and add the bitmap rep to it...
            image = NSImage.alloc.init
            #image.addRepresentation(bitmapRep)
            #bitmapRep.release
            # Set the output view to the new NSImage.
            #[outputView setImage:image];
            
            
            
            
            #Create paths to output images
            #NSString  *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Test.png"];
            #NSString  *jpgPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Test.jpg"];
            jpgPath = NSHomeDirectory().stringByAppendingPathComponent("Documents/Text.jpg")
            puts "jpgPath: #{jpgPath}"
            # Write a UIImage to JPEG with minimum compression (best quality)
            # The value 'image' must be a UIImage object
            # The value '1.0' represents image compression quality as value from 0.0 to 1.0
            #bitmapRep.representationUsingType(NSJPEGFileType).writeToFile(jpgPath, :atomically => YES)
            bitmapRep.TIFFRepresentation.writeToFile(jpgPath, :atomically => true)
            
            #upload file to server
            
            file = File.open jpgPath, 'r'
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
                nsurl = NSURL.URLWithString("http://#{@url}")
                
                add_text_to_clipboard(nsurl)
                
                #clickable_link = NSAttributedString.hyperlinkFromString("See on upscrn", withURL:nsurl)
                puts "url = #{@url}"
                #@url_label.stringValue = nsurl
                show_screenshot_url(@url, nsurl)
            rescue Exception => e
                @url_label.stringValue = e.message
            end
            
        else
            
            #[outputView setImage:nil];
        end
    end
    
    def show_screenshot_url(link_text, nsurl)
        # both are needed, otherwise hyperlink won't accept mousedown
        @url_label.setAllowsEditingTextAttributes(true)
        @url_label.setSelectable(true)
        
        url_string = NSMutableAttributedString.alloc.init
        url_string.appendAttributedString(hyperlink_from_string(link_text, nsurl))
        
        # set the attributed string to the NSTextField
        @url_label.setAttributedStringValue(url_string)
    end
    
    def add_text_to_clipboard(text)
        pasteboard = NSPasteboard.generalPasteboard
        changeCount = pasteboard.clearContents
        ok = pasteboard.writeObjects([text])
    end
    
    #from http://developer.apple.com/library/mac/#qa/qa1487/_index.html
    def hyperlink_from_string(text, url)
        attrString = NSMutableAttributedString.alloc.initWithString(text)
        
        range = NSMakeRange(0, attrString.length)
        
        attrString.beginEditing
        attrString.addAttribute(NSLinkAttributeName, value:url.absoluteString, range:range)
        
        # make the text appear in blue
        attrString.addAttribute(NSForegroundColorAttributeName, value:NSColor.blueColor, range:range)
        
        # next make the text appear with an underline
        attrString.addAttribute(NSUnderlineStyleAttributeName, value:NSNumber.numberWithInt(NSSingleUnderlineStyle), range:range)
        
        attrString.endEditing
        attrString
    end

end