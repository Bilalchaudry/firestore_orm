# lib/firestore_orm/model.rb
require 'google/cloud/firestore'

module FirestoreOrm
  class Model
    attr_accessor :attributes

    def initialize(attributes = {})
      @attributes = attributes
    end

    def save
      collection_ref.document(id || SecureRandom.uuid).set(@attributes)
    end

    def update(attributes)
      collection_ref.document(id).update(attributes)
      @attributes.merge!(attributes)
    end

    def delete
      collection_ref.document(id).delete
    end

    def id
      @attributes[:id]
    end

    class << self
      def find(id)
        doc = collection_ref.document(id).get
        new(doc.data.merge(id: doc.document_id)) if doc.exists?
      end

      def where(conditions = {})
        query = collection_ref
        conditions.each do |field, value|
          query = query.where(field, '=', value)
        end
        query.get.map do |doc|
          new(doc.data.merge(id: doc.document_id))
        end
      end

      def first_or_create(conditions, attributes = {})
        where(conditions).first || create(attributes.merge(conditions))
      end

      def create(attributes = {})
        model = new(attributes)
        model.save
        model
      end

      def collection(collection_name = nil)
        @collection_name ||= collection_name || name.downcase.pluralize
      end

      private

      def collection_ref
        firestore.collection(@collection_name || name.downcase.pluralize)
      end

      def firestore
        @firestore ||= Google::Cloud::Firestore.new
      end
    end
  end
end
