require 'active_support'
require 'active_support/core_ext/hash/conversions'
require 'action_dispatch'
require 'action_dispatch/http/request'
require 'action_pack/xml_parser/version'
require 'nokogiri'

module ActionPack
  class XmlParser
    def self.register
      original_parsers = ActionDispatch::Request.parameter_parsers
      ActionDispatch::Request.parameter_parsers = original_parsers.merge(Mime[:xml].symbol => self)
    end

    def self.call(raw_post)
      hash_from_xml(raw_post) || {}
    end

    private

    def hash_from_xml(xml_io)
      result = Nokogiri::XML(xml_io)
      { result.root.name.to_sym => xml_node_to_hash(result.root) }
    end

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
        result = xml_node_to_hash(child)

        if child.name == 'text'
          return prepare(result) unless child.next_sibling || child.previous_sibling
        elsif result_hash[child.name.to_sym]
          if result_hash[child.name.to_sym].is_a?(Object::Array)
            result_hash[child.name.to_sym] << prepare(result)
          else
            result_hash[child.name.to_sym] = [result_hash[child.name.to_sym]] << prepare(result)
          end
        else
          result_hash[child.name.to_sym] = prepare(result)
        end
      end

      result_hash
    end

    def prepare(data)
      data.instance_of?(String) && data.to_i.to_s == data ? data.to_i : data
    end
  end
end
