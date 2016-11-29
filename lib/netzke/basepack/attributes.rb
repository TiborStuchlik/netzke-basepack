module Netzke
  module Basepack
    # This module is encluded in +Grid+, +Form+, and +Tree+. It allows configuring specific model attributes.
    #
    # To override default configuration for a model attribute (e.g. to change its label or read-only property) use the
    # +attribute_overrides+ configuration option for the component, or the +attribute+ DSL method. This will have effect
    # on both columns and form fields.
    #
    # For example, to make the address attribute read-only:
    #
    #      class Users < Netzke::Grid::Base
    #        def configure(c)
    #          super
    #          c.model = User
    #        end
    #
    #        attribute :address do |c|
    #          c.read_only = true
    #        end
    #      end
    #
    # Using the +attribute_overrides+ config option may be handy when building composite components. E.g. in a tab panel
    # nesting multiple grids, you may want to override specific attributes for a specific grid:
    #
    #      class ManagmentPanel < Netzke::Base
    #        client_class do |c|
    #          c.extend = "Ext.tab.Panel"
    #        end
    #
    #        def configure(c)
    #          super
    #          c.items = [:users, :roles]
    #        end
    #
    #        component :users do |c|
    #          c.attribute_overrides = {
    #            birth_date: {
    #              excluded: true # exclude this column from the grid and forms
    #            }
    #          }
    #        end
    #
    #        component :roles
    #      end
    #
    # Another way to override attributes is by overriding the +augment_attribute_config+ method:
    #
    #      class Users < Netzke::Grid::Base
    #        def configure(c)
    #          super
    #          c.model = User
    #        end
    #
    #        def augment_attribute_config(c)
    #          super
    #          c.read_only = true if [:address, :salary].include?(c.name)
    #        end
    #      end
    #
    # The following attribute config options are available:
    #
    # [label]
    #
    #   Field label and/or column title used for this attribute. Defaults to
    #   `ActiveRecord::Base.human_attribute_name(attribute)`, which means that this value will be localized according to
    #   Rails conventions.
    #
    # [read_only]
    #
    #   A boolean that defines whether the attribute should be editable via grid/form.
    #
    # [getter]
    #
    #   A lambda that receives a record as a parameter, and is expected to return the value used in the grid cell or
    #   form field, e.g.:
    #
    #     getter: lambda {|r| [r.first_name, r.last_name].join }
    #
    #   In case of relation used in relation, passes the last record to lambda, e.g.:
    #
    #     name: author__books__first__name, getter: lambda {|r| r.title }
    #     r #=> author.books.first
    #
    # [setter]
    #
    #   A lambda that receives a record as first parameter, and the value passed from the cell/field as the second parameter,
    #   and is expected to modify the record accordingly, e.g.:
    #
    #     setter: lambda {|r,v| r.first_name, r.last_name = v.split(" ") }
    #
    # [scope]
    #
    #   A Proc or a Hash used to scope out one-to-many association options. Same syntax applies as for scoping out records in the grid.
    #
    # [filter_association_with]
    #
    #   A Proc object that receives the relation and the value to filter by. Example:
    #
    #     attribute :author__name do |c|
    #       c.filter_association_with = lambda {|rel, value| rel.where("first_name like ? or last_name like ?", "%#{value}%", "%#{value}%" ) }
    #     end
    #
    # [format]
    #
    #   The format to display data in case of date and datetime attributes, e.g. 'Y-m-d g:i:s'.
    #
    # [excluded]
    #
    #   When true, this attribute will not be used
    #
    # [meta]
    #
    #   When set to +true+, the data for this column will be available in the grid store, but the actual column won't be
    #   created (as if +excluded+ were set to +true+).
    #
    # [type]
    #
    #   When adding a virtual attribute to the grid, it may be useful to specify its type, so the column editor (and the
    #   form field) are configured properly.
    #
    # [escape_html]
    #
    #   When +true+, the value will be HTML-escaped before sending it to the browser. Defaults to +nil+.
    #
    # [column_config]
    #
    #   Configuration specific for the corresponding grid column. For example:
    #
    #        attribute :address do |c|
    #          c.column_config = { width: 200 }
    #        end
    #
    # [field_config]
    #
    #   Configuration for the corresponding form field. For example:
    #
    #        attribute :address do |c|
    #          c.field_config = { xtype: :displayfield }
    #        end
    #
    # [editor_config]
    #
    #   Additional configuration for column editor and form field (which are usually represented by the same Ext field
    #   component). Any common Ext config option like `min_chars` and `format` are accepted. Besides, Netzke extends it
    #   with some extras:
    #
    #   [blank_line]
    #
    #     The blank line for one-to-many association columns, defaults to "---". Set to false to exclude completely.
    #
    #   [date_format]
    #
    #     In case of datetime type, the format date must be entered in the editor.
    #
    #   [time_format]
    #
    #     In case of datetime type, the format time must be entered in the editor.
    module Attributes
      extend ActiveSupport::Concern

      ATTRIBUTE_METHOD_NAME = "%s_attribute"

      included do
        class_attribute :declared_attribute_names
        self.declared_attribute_names = []
      end

      module ClassMethods
        # Adds/overrides an attribute config, e.g.:
        #
        #     attribute :price do |c|
        #       c.read_only = true
        #     end
        def attribute(name, &block)
          method_name = ATTRIBUTE_METHOD_NAME % name
          define_method(method_name, &block)

          # we *must* use a writer here
          self.declared_attribute_names = declared_attribute_names + [name]
        end
      end

      # Returns the list of (non-normalized) attributes to be used.
      # Can be overridden.
      def attributes
        config.attributes || model_adapter.model_attributes
      end

      def attribute_overrides
        return @attribute_overrides if @attribute_overrides

        declared = (attributes | self.class.declared_attribute_names).reduce({}) do |res, name|
          c = Netzke::Basepack::AttrConfig.new(name, model_adapter)
          augment_attribute_config(c)
          res.merge!(name => c)
        end

        @attribute_overrides = (config.attribute_overrides || {}).deep_merge(declared)
      end

      # Extends passed column config with DSL declaration for this column
      def apply_attribute_dsl(c)
        method_name = ATTRIBUTE_METHOD_NAME % c.name
        send(method_name, c) if respond_to?(method_name)
      end

      # Receives a +Netzke::Basepack::AttrConfig+ with minimum attribute configuration and extends it according to the
      # attribute's type. May be overridden.
      def augment_attribute_config(c)
        apply_attribute_dsl(c)
        c.set_defaults
      end

      def association_attr?(attr)
        !!attr[:name].to_s.index("__")
      end

      # Returns a hash of association attribute default values. Used when creating new records with association attributes that have a default value.
      def association_value_defaults(cols)
        @_default_association_values ||= {}.tap do |values|
          cols.each do |c|
            next unless association_attr?(c) && c[:default_value]

            assoc_name, assoc_method = c[:name].split '__'
            assoc_class = model_adapter.class_for(assoc_name)
            assoc_data_adapter = Netzke::Basepack::DataAdapters::AbstractAdapter.adapter_class(assoc_class).new(assoc_class)
            assoc_instance = assoc_data_adapter.find_record c[:default_value]
            values[c[:name]] = assoc_instance.send(assoc_method)
          end
        end
      end
    end
  end
end
