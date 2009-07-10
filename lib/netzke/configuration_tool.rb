module Netzke
  #
  # Include this module into any widget if you want a "Properties" tool button in the top toolbar which will triggger a modal window, which will load the Accordion widgets, which in its turn will contain all the aggregatees specified in "configuration_widgets" method (*must* be defined)
  #
  module ConfigurationTool
    def self.included(base)
      base.extend ClassMethods
      
      base.class_eval do
        # replacing instance methods
        [:tools, :initial_aggregatees].each{ |m| alias_method_chain m, :properties }

        # replacing class methods
        class << self
          alias_method_chain :js_extend_properties, :properties
        end
      end

      # if you include ConfigurationTool, you must define configuration_widgets method which will returns an array of arrgeratees that will be included in the property window (each in its own tab or accordion pane)
      raise "configuration_widgets method undefined" unless base.instance_methods.include?("configuration_widgets")
    end

    module ClassMethods
      def js_extend_properties_with_properties
        js_extend_properties_without_properties.merge({
          :gear => <<-JS.l
            function(){
              var w = new Ext.Window({
                title:'Config',
                layout:'fit',
                modal:true,
                width: Ext.lib.Dom.getViewWidth() *0.9,
                height: Ext.lib.Dom.getViewHeight() *0.9,
                closeAction:'destroy',
                buttons:[{
                  text:'Submit',
                  handler:function(){
                    this.ownerCt.closeRes = 'OK'; 
                    this.ownerCt.close();
                  }
                }]

              });

              w.show(null, function(){
                w.loadWidget(this.initialConfig.id+"__properties__get_widget");
              }, this);

              w.on('close', function(){
                if (w.closeRes == 'OK'){
                  widget = this;
                  if (widget.ownerCt) {
                    widget.ownerCt.loadWidget(widget.initialConfig.api.getWidget);
                  } else {
                    this.feedback('Reload current window'); // we are embedded directly in HTML
                  }
                }
              }, this);
            }
          JS
        })
      end
    end

    def initial_aggregatees_with_properties
      res = initial_aggregatees_without_properties
      # Add the accordion as aggregatee, which in its turn aggregates widgets from the configuration_widgets method
      res.merge!(:properties => {:widget_class_name => 'TabPanel', :items => configuration_widgets, :ext_config => {:title => false}, :late_aggregation => true}) if config[:ext_config][:config_tool]
      res
    end

    def tools_with_properties
      tools = tools_without_properties
      # Add the toolbutton
      tools << 'gear' if config[:ext_config][:config_tool]
      tools
    end
  
  end
end