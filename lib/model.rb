require 'data_mapper'
require 'dm-types'
# require 'dm_noisy_failures'

class Repository
  include DataMapper::Resource

  property :id, Integer, :key => true
  property :name, String
  property :base_url, URI
  property :software_name, String
  property :software_version, String
  property :harvested, DateTime
  property :error, Boolean, :default => false
  
  has n, :repository_records
  has n, :metadata_formats, :through => Resource
end

class ValidationEvent
  include DataMapper::Resource
  
  property :id, Serial
  # property :repository_record_id, String#, :key => true
  # property :validation_scheme_id, String#, :key => true
  property :timestamp, DateTime
  property :valid, Boolean, :default => false
  
  has n, :issues
  belongs_to :repository_record
  belongs_to :validation_scheme
end

class ValidationScheme
  include DataMapper::Resource
  
  property :id, String, :key => true#, :writer => :private
  property :description, String, :length => 255
  
  # has n, :repository_records, :through => Resource
  # has n, :issues
  has n, :validation_events
end

class RepositoryRecord
  include DataMapper::Resource
  
  property :id, String, :key => true#, :writer => :private
  property :datestamp, DateTime, :writer => :private
  property :xml, Text
  property :repository_id, Integer, :required => false
  property :deleted, Boolean, :default => false
  
  belongs_to :repository
  belongs_to :metadata_format
  # has n, :issues
  #   has n, :validation_schemes, :through => Resource
  has n, :validation_events
  
  def xml=(xml_doc)
    super
    header = xml_doc.find_first('header')
    self.datestamp = header.find_first('datestamp').content
    if header.attributes.get_attribute('status') != nil && header.attributes.get_attribute('status').value.downcase == 'deleted' then
      self.deleted = true
    end
  end
  
end

class Issue
  include DataMapper::Resource
  
  property :id, Serial
  property :issue_type, Enum[:UNPECIFIED_ERROR, :TOO_FEW_VALUES, :TOO_MANY_VALUES, :EMPTY_STRING_VALUES, :INVALID_HTTP_URI, :INVALID_ISO8601_DATE, :INVALID_MIME_TYPE, :INVALID_ISO639_3_LANGUAGE_CODE, :INVALID_NAME, :MISSING_VALUE, :INVALID_TERM], :default => :UNPECIFIED_ERROR
  property :property_name, String
  property :severity, Enum[:FATAL,:ERROR,:WARN,:SUGGEST]
  property :message, String, :length => 255
  
  # belongs_to :repository_record
  # belongs_to :validation_scheme
  belongs_to :validation_event
end

class MetadataFormat
  include DataMapper::Resource
  
  property :prefix, String, :key => true
  property :uri, URI
  
  has n, :repository_records
  has n, :repositories, :through => Resource
end