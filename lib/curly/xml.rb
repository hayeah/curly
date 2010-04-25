class Curly::XML
  def initialize(source)
    @source = source
    @parse = Curly::Parser.new(source).parse
  end

  def generate
    build_xml(@parse)
  end

  def build_xml(element)
    doc = Nokogiri::XML::Document.new
    doc.add_child(build_node(doc,element))
    doc
  end

  protected

  def build_node(doc,element)
    head, attributes, children = element
    node = create_element(doc,head,attributes)
    children.each { |child|
      insert(node,child)
    }
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
