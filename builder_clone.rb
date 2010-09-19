# Builder clone (http://builder.rubyforge.org/)
# Started on 05/09/10

module XMLBuilder

  # Represents a tag, knows it's name, value, attributes and nested tags.
  class Tag

    attr_reader :repr, :name, :value, :attrs

    def initialize(name, value, attrs)
      @name = name
      @value = value
      @attrs = attrs
      @children = []
      @repr = create_repr
    end

    def insert_child(child)
      # tags with value never have children
      unless @value
        @children << child
        @repr = create_repr
      end
    end

    # Return an array representation of self.
    #
    # If the tag is self-closing (like HTML's <input ... />), that is, if it
    # has neither a value nor children, then this array only has 1 elem, said
    # tag.  If it has either of them, then the array has 3 sections: the first
    # is the opening tag, the middle one is the indented content (it's value as a
    # string or children as an array), and the last one is the closing tag.
    def create_repr
      @repr = []
      opening_tag = "<#{@name}"
      @attrs.each_pair do |k, v|
        opening_tag << " #{k}=\"#{v}\" "
      end
      opening_tag << "/" unless @value || @children.length > 0
      opening_tag << ">"
      @repr << opening_tag
      @repr << @value if @value
      # If there is a value, then @children will be empty.
      @children.each do |child|
        @repr << child.create_repr
      end
      @repr << "</#{@name}>" if @value || @children.length > 0
      @repr
    end

    # Return the final XML string for this tag.
    #
    # It recursively builds the XML string for it's children.  The params hash
    # expects 3 params: repr, the array representation of the current tag (self
    # or one of it's children); level, which tells the recursive call how deep
    # in nesting it is so it can handle indentation; and qty, the amount of
    # spaces to use when indenting.
    def render(params={})
      repr = params[:repr] || @repr
      level = params[:level] || 0
      qty = params[:qty] || 2
      output = " " * qty * level
      output << repr[0] + "\n"
      if repr.length > 1
        if (repr[1].is_a? String) && (repr[1] != "")
          output << " " * qty * level * 2
          output << repr[1] + "\n"
        else
          repr[1...-1].each do |child_repr|
            tmp = render(:repr => child_repr, :level => level + 1)
            output << tmp
          end
        end
        output << " " * qty * level
        output << repr[-1] + "\n"
      end
      output
    end
  end


  # Class that can construct every possible tag, with attributes, values and
  # nested tags (children).
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

    # Return the final string representation of the XML document.
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
