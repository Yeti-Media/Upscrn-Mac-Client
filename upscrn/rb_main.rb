#
#  rb_main.rb
#  upscrn
#
#  Created by Matthew Cowley on 8/30/11.
#  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'

#$:.unshift  File.join(File.dirname(__FILE__), 'vendor/json_pure/lib')
$:.unshift  File.join(File.dirname(__FILE__), 'vendor/upsrcn-client/lib')

# Loading all the Ruby project files.
main = File.basename(__FILE__, File.extname(__FILE__))
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Dir.glob(File.join(dir_path, '*.{rb,rbo}')).map { |x| File.basename(x, File.extname(x)) }.uniq.each do |path|
  if path != main
    require(path)
  end
end

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)
