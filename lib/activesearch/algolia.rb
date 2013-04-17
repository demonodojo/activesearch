require "activesearch/algolia/client"
require "activesearch/base"
require "activesearch/proxy"

module ActiveSearch
  def self.search(text)
    Proxy.new(text) do |text|
      Algolia::Client.new.query(text)["hits"].map! do |hit|
        if hit["_tags"]
          hit["_tags"].each do |tag|
            k, v = tag.split(':')
            hit[k] = v
          end
          hit.delete("_tags")
        end
        hit
      end
    end
  end
  
  module Algolia
    def self.included(base)
      base.class_eval do
        include Base
      end
    end
    
    protected
    def reindex
      algolia_client.save(algolia_id, self.to_indexable)
    end
    
    def deindex
      algolia_client.delete(algolia_id)
    end
    
    def algolia_id
      raise "You must define this method in your model."
    end
    
    def to_indexable
      doc = {}
      search_fields.each do |field|
        doc[field.to_s] = attributes[field.to_s] if attributes[field.to_s]
      end
      
      (Array(search_options[:store]) - search_fields).each do |field|
        doc["_tags"] ||= []
        doc["_tags"] << "#{field}:#{self.send(field)}"
      end
      doc
    end
    
    def algolia_client
      @algolia_client ||= Client.new
    end
  end
end