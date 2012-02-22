#
#  AppDelegate.rb
#  upscrn
#
#  Created by Matthew Cowley on 8/30/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#
$token_key = "upscrn_token"
$defaults = NSUserDefaults.standardUserDefaults


class AppDelegate
    attr_accessor :status_window
    attr_accessor :preferences_window
    attr_accessor :url_label
    attr_accessor :status_bar_menu
    attr_accessor :response_window
    attr_accessor :project_list
    attr_accessor :upload_window
    @projects = []
    
    def applicationDidFinishLaunching(a_notification)
        # Insert code here to initialize your application
        activateStatusBar
        $app_start_time = Time.now
        if ($defaults[$token_key].nil?  || $defaults[$token_key].length == 0)
            preferences_window.makeKeyAndOrderFront(NSApp)
        end
        Logger.debug "getting query"
        @query = NSMetadataQuery.alloc.init
        
        #get_projects
        
        NSNotificationCenter.defaultCenter.addObserver(self, selector: :"queryUpdated:", name:NSMetadataQueryDidStartGatheringNotification, object:@query)
        
        NSNotificationCenter.defaultCenter.addObserver(self,selector: :"queryUpdated:", name:NSMetadataQueryDidUpdateNotification, object:@query)
        
        NSNotificationCenter.defaultCenter.addObserver(self,selector: :"queryUpdated:", name:NSMetadataQueryDidFinishGatheringNotification, object:@query)
        @query.setDelegate(self)
        @query.setPredicate(NSPredicate.predicateWithFormat("kMDItemIsScreenCapture = 1"))
        @query.startQuery
        Logger.debug "got query"
        
        populate_project_list
        
        @url_label.setStringValue("waiting for a screenshot...")

    end
    
    def populate_project_list
        @projects ||= []
      projects = UpscrnClient.projects
        Logger.debug "\n\nprojects: #{projects}"
      projects["projects"].each do |p|
          @projects << p["id"]
          Logger.debug "\n\np: #{p}"
          @project_list.addItemWithObjectValue(p["name"])
      end
      @project_list.addItemsWithObjectValues( UpscrnClient.projects)
    end
    
    def applicationWillTerminate(a_notification)
        @query.stopQuery
        @query.setDelegate(nil)
        @query.release
        @query = nil
        self.setQueryResults(nil)
    end

    def queryUpdated(note)
        Logger.debug "query updated!"
        @result = Hash.new
        if @query.results.any?
            Logger.debug "filename: #{@query.results.last.valueForAttribute("kMDItemFSName")}"
            created_time = time_from_creation_date(@query.results.last.valueForAttribute("kMDItemContentCreationDate"))
            if created_time > $app_start_time
                Logger.debug "showing window"
              upload_window.makeKeyAndOrderFront(self)
            end
        end
        #self.setQueryResults(@query.results)
    end
    
    def refrestProjectList(sender)
        @projects = []
        project_list.removeAllItems
        populate_project_list
    end
    
    def doUpload(sender)
        project_name = project_list.objectValueOfSelectedItem
        project_id = project_list.indexOfSelectedItem == -1 ? nil : @projects[project_list.indexOfSelectedItem]
        Logger.debug "upload - project=#{project_name}"
        Logger.debug "index: #{project_list.indexOfSelectedItem}"
        queue = Dispatch::Queue.new('com.yeti.upsrcrn.gcd')
        queue.async do
            Logger.debug "setting status..."
            @url_label.setStringValue("uploading...")
            status_window.makeKeyAndOrderFront(self)
            upload_window.orderOut(self)
        end
        queue.async do
            
            #dump_query_atttributes
            @result = UpscrnClient.upload_screenshot(@query.results.last.valueForAttribute("kMDItemFSName"), project_id)
            Logger.debug "result: #{@result}"
            if @result['success']
                @url_label.setStringValue("success!")
                url = @result['url']
                nsurl = NSURL.URLWithString("http://#{url}")
                
                add_text_to_clipboard(nsurl)
                show_screenshot_url(url, nsurl)
                else
                Logger.debug "setting error label"
                @url_label.setStringValue(@result['error'])
            end
            status_window.makeKeyAndOrderFront(self)
        end
        
    end
    
    

    def time_from_creation_date(cdate)
      if cdate.to_s.match(/(\d\d\d\d)-(\d\d)-(\d\d)\s(\d\d):(\d\d):(\d\d)/)
        Time.local($1,$2,$3,$4,$5,$6)
      else
        $app_start_time
      end
    end
     
    def dump_query_attributes
         @query.results.last.attributes.each do |key|
            value = @query.results.last.valueForAttribute("#{key}")
            Logger.debug "key: #{key}  value: #{value}"
        end
    end
                                                                                        
    def add_text_to_clipboard(text)
        pasteboard = NSPasteboard.generalPasteboard
        changeCount = pasteboard.clearContents
        ok = pasteboard.writeObjects([text])
    end
    
    def activateStatusBar
        bar = NSStatusBar.systemStatusBar
        
        theItem = bar.statusItemWithLength(NSVariableStatusItemLength)
        
        theItem.setTitle("upscrn")
        theItem.setHighlightMode(true)
        theItem.setMenu(status_bar_menu)
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

    def get_projects
        projects = UpscrnClient::Client.projects($defaults[$token_key])
        Logger.debug "*** projects: #{projects.inspect}"
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

    # Persistence accessors
    attr_reader :persistentStoreCoordinator
    attr_reader :managedObjectModel
    attr_reader :managedObjectContext

    #
    # Returns the directory the application uses to store the Core Data store file. This code uses a directory named "upscrn" in the user's Library directory.
    #
    def applicationFilesDirectory
        file_manager = NSFileManager.defaultManager
        library_url = file_manager.URLsForDirectory(NSLibraryDirectory, inDomains:NSUserDomainMask).lastObject
        library_url.URLByAppendingPathComponent("upscrn")
    end

    #
    # Creates if necessary and returns the managed object model for the application.
    #
    def managedObjectModel
        unless @managedObjectModel
          model_url = NSBundle.mainBundle.URLForResource("upscrn", withExtension:"momd")
          @managedObjectModel = NSManagedObjectModel.alloc.initWithContentsOfURL(model_url)
        end
        
        @managedObjectModel
    end

    #
    # Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    #
    def persistentStoreCoordinator
        return @persistentStoreCoordinator if @persistentStoreCoordinator

        mom = self.managedObjectModel
        unless mom
            Logger.debug "#{self.class} No model to generate a store from"
            return nil
        end

        file_manager = NSFileManager.defaultManager
        directory = self.applicationFilesDirectory
        error = Pointer.new_with_type('@')

        properties = directory.resourceValuesForKeys([NSURLIsDirectoryKey], error:error)

        if properties.nil?
            ok = false
            if error[0].code == NSFileReadNoSuchFileError
                ok = file_manager.createDirectoryAtPath(directory.path, withIntermediateDirectories:true, attributes:nil, error:error)
            end
            if ok == false
                NSApplication.sharedApplication.presentError(error[0])
            end
        elsif properties[NSURLIsDirectoryKey] != true
                # Customize and localize this error.
                failure_description = "Expected a folder to store application data, found a file (#{directory.path})."

                error = NSError.errorWithDomain("YOUR_ERROR_DOMAIN", code:101, userInfo:{NSLocalizedDescriptionKey => failure_description})

                NSApplication.sharedApplication.presentError(error)
                return nil
        end

        url = directory.URLByAppendingPathComponent("upscrn.storedata")
        @persistentStoreCoordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(mom)

        unless @persistentStoreCoordinator.addPersistentStoreWithType(NSXMLStoreType, configuration:nil, URL:url, options:nil, error:error)
            NSApplication.sharedApplication.presentError(error[0])
            return nil
        end

        @persistentStoreCoordinator
    end

    #
    # Returns the managed object context for the application (which is already
    # bound to the persistent store coordinator for the application.) 
    #
    def managedObjectContext
        return @managedObjectContext if @managedObjectContext
        coordinator = self.persistentStoreCoordinator

        unless coordinator
            dict = {
                NSLocalizedDescriptionKey => "Failed to initialize the store",
                NSLocalizedFailureReasonErrorKey => "There was an error building up the data file."
            }
            error = NSError.errorWithDomain("YOUR_ERROR_DOMAIN", code:9999, userInfo:dict)
            NSApplication.sharedApplication.presentError(error)
            return nil
        end

        @managedObjectContext = NSManagedObjectContext.alloc.init
        @managedObjectContext.setPersistentStoreCoordinator(coordinator)

        @managedObjectContext
    end

    #
    # Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    #
    def windowWillReturnUndoManager(window)
        self.managedObjectContext.undoManager
    end

    #
    # Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    #
    def saveAction(sender)
        error = Pointer.new_with_type('@')

        unless self.managedObjectContext.commitEditing
          Logger.debug "#{self.class} unable to commit editing before saving"
        end

        unless self.managedObjectContext.save(error)
            NSApplication.sharedApplication.presentError(error[0])
        end
    end

    def applicationShouldTerminate(sender)
        # Save changes in the application's managed object context before the application terminates.

        return NSTerminateNow unless @managedObjectContext

        unless self.managedObjectContext.commitEditing
            Loggder.debug "%@ unable to commit editing to terminate" % self.class
        end

        unless self.managedObjectContext.hasChanges
            return NSTerminateNow
        end

        error = Pointer.new_with_type('@')
        unless self.managedObjectContext.save(error)
            # Customize this code block to include application-specific recovery steps.
            return NSTerminateCancel if sender.presentError(error[0])

            alert = NSAlert.alloc.init
            alert.messageText = "Could not save changes while quitting. Quit anyway?"
            alert.informativeText = "Quitting now will lose any changes you have made since the last successful save"
            alert.addButtonWithTitle "Quit anyway"
            alert.addButtonWithTitle "Cancel"

            answer = alert.runModal
            return NSTerminateCancel if answer == NSAlertAlternateReturn
        end

        NSTerminateNow
    end
end

