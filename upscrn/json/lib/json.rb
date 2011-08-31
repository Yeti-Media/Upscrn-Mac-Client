require 'json/lib/json/common'
module JSON
  require 'json/lib/json/version'

  begin
    require 'json/lib/json/ext'
  rescue LoadError
    require 'json/lib/json/pure'
  end
end
