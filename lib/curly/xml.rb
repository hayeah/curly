class Curly::XML
  def self.xml(source)
    self.new(source).xml
  end
  
  def initialize(source)
    @source = source
    @parse = Curly::Parser.new(source).parse
  end

  def generate
    Builder.xml(@parse)
  end

  class Builder
    # tag ::= [head,attr,children]
    # attr ::= Hash || nil
    # children ::= [tag*]
    def self.xml(tag)
      self.new(tag).build
    end

    def self.node(tag)
      xml(tag).root
    end
    
    def initialize(tag)
      @tag = tag
    end

    def build
      build_xml(@tag)
    end


    def build_xml(element)
      doc = Nokogiri::XML::Document.new
      doc.add_child(build_node(doc,element))
      doc
    end

    class EmptyTagName < StandardError
    end

    def build_node(doc,element)
      head, attributes, children = element
      head = head.to_s
      raise EmptyTagName if head.empty?
      node = create_element(doc,head,attributes || {})
      if children
        children.each { |child|
          insert(node,child)
        }
      end
      node
    end

    def create_element(doc,head,attributes)
      attributes = attributes.inject({}) { |h,(k,v)|
        h[k] = v; h
      }
      name, id, classes = parse_tag_name(head)
      node = doc.create_element(name,attributes)
      if id
        node["id"] = id
      end
      if !classes.empty?
        node["class"] = classes.join(" ")
      end
      node
    end

    def insert(node,element)
      doc = node.document
      case element
      when String
        node << doc.create_text_node(element)
      when Array
        head, attributes, body = element
        case head
        when %s(!)
          # do nothing
        when :cdata
          node << Nokogiri::XML::CDATA.new(doc, body.to_s)
        else
          child = build_node(node.document,element)
          node << child
        end
      end
    end

    def parse_tag_name(head)
      head = head.to_s
      id = nil
      head.gsub!(/#([^.]*)/) { |match|
        id = $1
        raise "empty id" if id.empty?
        ""
      }
      tokens = head.split(".")
      head = tokens.shift
      classes = tokens

      raise "empty head" if head.empty?
      
      return [head,id,classes]
    end
  end
end
