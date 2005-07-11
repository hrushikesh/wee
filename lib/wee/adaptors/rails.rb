class Wee::PagelessComponentDriver < Wee::ComponentRunner
  attr_accessor :callbacks

  def initialize(root_component, callbacks=nil)
    super(root_component)
    @callbacks = callbacks
    @mutex = Mutex.new
  end

  def render(*args)
    @mutex.synchronize { super }
  end

  def process_callbacks(*args)
    @mutex.synchronize { super }
  end
end

class Wee::Component
  def renderer_class
    Wee::Rails::HtmlCanvasRenderer
  end
end

class Wee::RenderingContext
  attr_accessor :component_name
  attr_accessor :controller
  attr_accessor :redirect_action
end

module Wee::Rails

  class HtmlCanvasRenderer < Wee::HtmlCanvasRenderer
    def build_url(hash={})
      cid = hash[:callback_id]
      url = rendering_context.controller.url_for :action => 'callback'
      url << "?__c=#{ rendering_context.component_name }"
      url << "&__a=#{ rendering_context.redirect_action }" if rendering_context.redirect_action 
      url << "&#{ cid }" if cid
      url
    end
  end

  module ControllerClassMixin
    def register_component(name, &block)
      registered_components[name] = block
    end

    def registered_components
      @@registered_components ||= Hash.new
    end

    def scaffold_with_component(name=nil, &block)
      name ||= self.name
      register_component(name, &block) if block
      send(:define_method, :index) do
        show_component name
      end
    end
  end

  module ControllerMixin

    def self.included(klass)
      klass.extend(ControllerClassMixin)
    end

    public

    def callback
      c = components[@params['__c']]
      raise "no component found" if c.nil?
      callback_stream = Wee::CallbackStream.new(c.callbacks, @params)
      c.process_callbacks(callback_stream)
      redirect_to :action => (@params['__a'] || "index")
    end

    protected

    def make_component(name, obj)
      if components.has_key?(name)
        raise "disallowed to overwrite component #{ name }"
      else
        components[name] = Wee::PagelessComponentDriver.new(obj, Wee::CallbackRegistry.new(Wee::SimpleIdGenerator.new))
      end
    end

    def drop_component(name)
      if components.has_key?(name)
        components.delete(name)
      else
        raise "component #{ name } not found"
      end
    end

    def has_component?(name)
      components.has_key?(name)
    end

    def _show_component(name, hash={})
      cb = Wee::CallbackRegistry.new(Wee::SimpleIdGenerator.new)
      out = ''
      ctx = Wee::Context.new(@request, @response, @session)
      rctx = Wee::RenderingContext.new(ctx, cb, Wee::HtmlWriter.new(out))
      rctx.component_name = name
      rctx.controller = self
      rctx.redirect_action = hash[:redirect_action]

      unless c = components[name]
        if block = self.class.registered_components[name]
          make_component name, block.call
          c = components[name]
        end
      end

      raise "component #{ name } not found" if c.nil?

      c.render(rctx)
      c.callbacks = cb
      out
    end

    def show_component(name, hash={})
      render_text(_show_component(name, hash))
    end

    def components
      @session[:COMPONENTS] ||= Hash.new
    end

  end

end # module Wee::Rails

class ActionView::Base
  include Wee::Rails::ControllerMixin
  alias show_component _show_component
end