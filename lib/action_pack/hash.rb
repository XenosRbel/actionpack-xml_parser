# frozen_string_literal: true

require 'nokogiri'

class Hash
  class << self
    def from_xml(xml_io)
      result = Nokogiri::XML(xml_io)
      { result.root.name.to_sym => xml_node_to_hash(result.root) }
    end

    private

    def xml_node_to_hash(node)
      return prepare(node.content.to_s) unless node.element?

      result_hash = {}
      if node.attributes != {}
        result_hash[:attributes] = {}
        node.attributes.each_key do |key|
          result_hash[:attributes][node.attributes[key].name.to_sym] = prepare(node.attributes[key].value)
        end
      end

      return result_hash unless node.children.size.positive?

      node.children.each do |child|
        next if child.name == 'text'

        result = xml_node_to_hash(child)

        if result_hash[child.name.to_sym]
          if result_hash[child.name.to_sym].is_a?(Array)
            result_hash[child.name.to_sym] << prepare(result)
          else
            result_hash[child.name.to_sym] = [result_hash[child.name.to_sym], prepare(result)].flatten
          end
        else
          result_hash[child.name.to_sym] = prepare(result)
        end
      end

      result_hash
    end

    def prepare(data)
      Integer(data)
    rescue _
      data
    end
  end
end