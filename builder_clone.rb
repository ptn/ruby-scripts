# Builder clone
# 05/09/2010

# This program provides an XML generator in Ruby.  Summary:
#
#   | ruby code              | xml translation         |
#   | method                 | tag                     |
#   | block argument         | nested tag              |
#   | positional parameter   | value of tag            |
#   | keyword argument       | attribute for a tag     |
#   | 'end' reserved keyword | close corresponding tag |
#   |                        |                         |
#

module XMLBuilder

  # Represents a tag, knows it's name, value, attributes and nested tags.
  class Tag

    attr_reader :repr

    def initialize(name, value, attrs)
      @name = name
      @value = value
      @attrs = attrs
      @children = []
      # 3-elem array: first is opening tag, middle is indented content (value or
      # children), last is closing tag.
      @repr = create_repr
    end

    def insert_child(child)
      # tags with value can't have children and viceversa
      #XXX should this fail silently?
      unless @value
        @children << child
        @repr = create_repr
      end
    end

    # Form the array representation of self.
    def create_repr
      @repr = []
      opening_tag = "<#{@name}"
      #BUG There is no closing tag if there's no value
      closing_tag = "</#{@name}>"
      @attrs.each_pair do |k, v|
        opening_tag << " #{k}=\"#{v}\" "
      end
      opening_tag << ">"
      @repr << opening_tag
      @repr << @value if @value
      # If there was a value, then @children will be empty.
      @children.each do |child|
        @repr << child.create_repr
      end
      @repr << closing_tag
      @repr
    end

    # Return the final XML string.
    #
    # The param tells every recursive call how deep in indentation it is so it
    # knows how many tabs to insert.
    def render(repr=@repr, indent=0)
      output = "\t" * indent
      output << repr[0] + "\n"
      if repr.length > 2
        if (repr[1].is_a? String) && (repr[1] != "")
          output << "\t" * indent * 2
          output << repr[1] + "\n"
        else
          repr[1...-1].each do |child_repr|
            tmp = render(child_repr, indent + 1)
            output << tmp + "\n"
          end
        end
      end
      output << "\t" * indent
      output << repr[-1] + "\n"
      output
    end
  end


  class XMLBuilder::XMLBuilder

    def initialize
      @root_tag = Tag.new "xml", nil, {}
      # @current_tag is the tag that receives the children.
      @current_tag = @root_tag
    end

    def method_missing(tagname, *args, &blk)
      case args.length
      when 0
        value = nil
        attrs = {}
      when 1
        if args[0].is_a? Hash
          value = nil
          attrs = args[0]
        elsif args[0].is_a? String
          value = args[0]
          attrs = {}
        end
      when 2
        value = args[0]
        attrs = args[1]
      end
      tag = Tag.new tagname, value, attrs
      @current_tag.insert_child tag
      if blk
        tmp = @current_tag
        @current_tag = tag
        blk.call
        @current_tag = tmp
      end
    end

    # Form the final string representation of the XML document.
    def render
      @root_tag.render
    end
  end
end


if __FILE__ == $0
  xml = XMLBuilder::XMLBuilder.new
  xml.person do
    xml.name "Pablo", :capitalize => 1
    xml.surname do
      xml.father_surname "Torres"
      xml.mother_surname "Navarrete"
    end
  end
  xml.novaluenoattrs
  xml.novalueyesattrs :at1 => "1", :at2 => "2"
  puts xml.render
end
