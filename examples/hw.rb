$LOAD_PATH.unshift "../lib"
require 'rubygems' if RUBY_VERSION < "1.9"
require 'wee'

class HelloWorld < Wee::RootComponent
  def render(r)
    r.h1 "Hello World from Wee!"
  end
end

Wee.run(HelloWorld) if __FILE__ == $0
