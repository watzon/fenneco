class Fennec < Proton::Client
  annotation Help; end

  class ModuleHelp
    record HelpItem, description : String, arguments : Hash(String, String)?, usage : String?

    # A map of category name => [module name]
    getter cat_map : Hash(String, Set(String))

    # A map of module name => HelpItem
    getter help_map : Hash(String, HelpItem)

    def initialize
      @cat_map  = {} of String => Set(String)
      @help_map = {} of String => HelpItem
    end

    def self.from_annotations
      help = ModuleHelp.new

      {% begin %}
        {% for method in Fennec.methods %}
          {% for ann in method.annotations(Help) %}
            {% filedir = ann.filename.stringify.split('/')[-2] %}
            %category = {{ ann[:category] || filedir }}
            %name = {{ ann[:name] || method.name.stringify.gsub(/_command$/, "").gsub(/_/, " ") }}
            %description = {{ ann[:desc] || ann[:description] || "no description provided" }}
            %usage = {{ ann[:usage] }}

            %arguments = {{ ann[:args] || ann[:arguments] }}
            %arguments = %arguments.try &.to_h
              .transform_keys(&.to_s)
              .transform_values(&.to_s)

            help.add_help(%category, %name, %description, %arguments, %usage)
          {% end %}
        {% end %}
      {% end %}

      help
    end

    def add_help(category, name, description, arguments = nil, usage = nil)
      category = category.to_s.downcase
      @cat_map[category] ||= Set(String).new
      @cat_map[category] <<  name

      name = name.to_s.downcase
      @help_map[name] = HelpItem.new(description, arguments, usage)
    end

    def render_help
      categories = cat_map.keys
      Utils::MarkdownBuilder.build do
        section do
          bold("Fenneco Help")
          text("Use `.help [module name]` to get help for a specific module")
        end

        text("\n")

        categories.each do |cat|
          section do
            bold(cat)
            modules = cat_map[cat]
            if modules.empty?
              italic("No modules in this category")
            else
              text(modules.map { |mod| "`#{mod}`" }.join(", "))
            end
          end
        end
      end
    end

    def render_help_for(name)
      name = name.to_s.downcase
      if help_item = help_map[name]?
        Utils::MarkdownBuilder.build do
          section do
            bold(name)
            text(help_item.description)
          end

          if arguments = help_item.arguments
            text("\n")
            section do
              bold("args")
              arguments.each do |name, desc|
                key_value_item(bold(name), desc)
              end
            end
          end

          if usage = help_item.usage
            text("\n")
            section do
              bold("usage")
              code(usage)
            end
          end
        end
      end
    end
  end
end
