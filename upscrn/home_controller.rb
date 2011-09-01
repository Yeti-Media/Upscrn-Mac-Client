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
    
    
    def grabScreenshot(sender)
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
    
    def uploadImage(cgImage)
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
            @url_label.stringValue = nsurl
            
            
            else
            
            #[outputView setImage:nil];
        end
    end
    
    def add_text_to_clipboard(text)
        pasteboard = NSPasteboard.generalPasteboard
        changeCount = pasteboard.clearContents
        ok = pasteboard.writeObjects([text])
    end
end