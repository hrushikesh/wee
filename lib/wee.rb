module Wee
  Version = "0.5.0"
end

require 'wee/core'

require 'wee/context'
require 'wee/application'
require 'wee/requesthandler'
require 'wee/request'
require 'wee/response'
require 'wee/session'

require 'wee/components'
require 'wee/snapshot_ext'

require 'wee/template'

require 'wee/renderer/html/writer'
require 'wee/renderer/html/brushes'
require 'wee/renderer/html/canvas'
Wee::DefaultRenderer = Wee::HtmlCanvas

require 'wee/idgen/simple'
require 'wee/idgen/md5'
