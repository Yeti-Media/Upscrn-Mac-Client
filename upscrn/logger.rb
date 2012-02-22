#
#  logger.rb
#  upscrn
#
#  Created by Matthew Cowley on 10/18/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#


class Logger
    @log_level = :debug
    def self.debug(s)
        unless @log_level == :none
            puts s
        end

    end
end