# Builder clone (http://builder.rubyforge.org/)
# Started on 05/09/10

module XMLBuilder

  # Represents a tag, knows it's name, value, attributes, nested tags and
  # comments.
  class Tag

    attr_reader :repr, :name, :value, :attrs

    def initialize(name, params={})
      @name = name
      @value = params[:value]
      @attrs = params[:attrs] || {}
      @comments = params[:comments] || []
      @children = []
    end

    def insert_child(child)
      # tags with value never have children
      @children << child unless @value
    end

    # Return the final XML string for this tag.
    #
    # It recursively builds the XML string for it's children.  The params hash
    # expects 2 params: level, which tells the recursive call how deep
    # in nesting it is so it can handle indentation; and indent, the amount of
    # spaces to use when indenting.
    def render(params={})
      level = params[:level] || 0
      indent = params[:indent] || 2
      indent_str = " " * indent * level
      output = ""
      if @comments.length > 0
        output << "\n" + indent_str
        join_str = "\n" + indent_str
        output << "<!-- " + @comments.join(join_str) + " --!>\n\n"
      end
      output << indent_str
      opening_tag = "<#{@name}"
      @attrs.each_pair do |k, v|
        opening_tag << " #{k}=\"#{v}\" "
      end
      opening_tag << "/" unless @value || @children.length > 0
      opening_tag << ">"
      output << opening_tag
      if @value
        output << "\n" + " " * indent * (level + 1) + @value
      elsif @children.length > 0
        @children.each do |child|
          output <<  "\n" + child.render(:level => level + 1, :indent => indent)
        end
      end
      output <<  "\n" + indent_str + "</#{@name}>" if @value || @children.length > 0
      output
    end
  end


  # Class that can construct every possible tag, with attributes, values and
  # nested tags (children).
  class XMLBuilder::XMLBuilder

    def initialize
      @root_tag = Tag.new "xml"
      # @current_tag is the tag that receives the children.
      @current_tag = @root_tag
      # to include in the next inserted tag
      @comments_buf = []
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
      tag = Tag.new tagname, value: value, attrs: attrs, comments: @comments_buf
      @comments_buf = []
      @current_tag.insert_child tag
      if blk
        tmp = @current_tag
        @current_tag = tag
        blk.call
        @current_tag = tmp
      end
    end

    # Adds comments to the next inserted tag.
    def comment!(str)
      @comments_buf << str
    end

    # Return the final string representation of the XML document.
    def render(params={})
      @root_tag.render :indent => params[:indent] || 2
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
  xml.comment! "Testing comments"
  xml.comment! "This should be a different line"
  xml.novalueyesattrs :at1 => "1", :at2 => "2"
  puts xml.render :indent => 4
end
