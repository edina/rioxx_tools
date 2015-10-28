require './lib/properties'
require 'xml'
require './lib/model'

class BaseValidator
  
  @validation_scheme_id = 'UNKNOWN'
  @validation_scheme_description = 'NO DESCRIPTION'
  @properties = {}
  
  def self.validate!(oai_pmh_record,logger)
    validation_scheme_record = ValidationScheme.first_or_create(:id => @validation_scheme_id, :description => @validation_scheme_description)
    validation_event = ValidationEvent.first(:repository_record_id => oai_pmh_record.id, :validation_scheme => validation_scheme_record)
    if validation_event then
      validation_event.timestamp = Time.now
      validation_event.issues.destroy
      validation_event.valid = false
      validation_event.save!
    else
      validation_event = ValidationEvent.new
      validation_event.repository_record_id = oai_pmh_record.id
      validation_event.validation_scheme = validation_scheme_record
      validation_event.timestamp = Time.now
      validation_event.valid = false
      validation_event.save!
    end
    validation_event.valid = true
    if !oai_pmh_record.deleted then
      @properties.each do |property|
        property_data = property.validate(XML::Document::string(oai_pmh_record.xml))
        if property_data.errors.count > 0 then
          validation_event.valid = false
          property_data.errors.each do |error|
            issue = Issue.create(
              :issue_type => error.error_type,
              :property_name => error.property_name,
              :message => error.message,
              :severity => error.severity,
              :validation_event_id => validation_event.id
            )
          end
        end
      end
    end
    validation_event.save!
    return validation_event.valid
  end

  def self.get_properties
    return @properties
  end
end

class RioxxValidator < BaseValidator
  @validation_scheme_id = 'RIOXX'
  @validation_scheme_description = 'Base RIOXX scheme designed for low-level interoperability'
  
  @properties = [
    RioxxFreeToReadProperty.new({'min' => 0, 'max' => 1}),
    RioxxLicenseRefProperty.new({'min' => 0, 'max' => nil}),
    RioxxStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:coverage'}),
    RioxxStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:description'}),
    RioxxMimeStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:format'}),
    RioxxHttpUriStringProperty.new( {'min' => 1, 'max' => 1, 'name' => 'dc:identifier'}),
    RioxxLanguageStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:language'}),
    RioxxStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:publisher'}),
    RioxxHttpUriStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:relation'}),
    RioxxStringProperty.new({'min' => 0, 'max' => 1, 'name' => 'dc:source'}),#TODO develop a type which checks for recommended ISSNs
    RioxxStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:subject'}),
    RioxxStringProperty.new({'min' => 1, 'max' => 1, 'name' => 'dc:title'}),
    RioxxDateStringProperty.new( {'min' => 0, 'max' => 1, 'name' => 'dcterms:dateAccepted'}),
    RioxxStringProperty.new({'min' => 0, 'max' => 1, 'name' => 'rioxxterms:apc'}),
    RioxxPartyProperty.new({'min' => 1, 'max' => nil, 'name' => 'rioxxterms:author'}),
    RioxxPartyProperty.new({'min' => 0, 'max' => nil, 'name' => 'rioxxterms:contributor'}),
    RioxxProjectProperty.new({'min' => 0, 'max' => nil}),
    RioxxStringProperty.new({'min' => 0, 'max' => 1, 'name' => 'rioxxterms:publication_date'}),
    RioxxStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'rioxxterms:type'}),
    RioxxStringProperty.new({'min' => 0, 'max' => 1, 'name' => 'rioxxterms:version'}),
    RioxxHttpUriStringProperty.new({'min' => 0, 'max' => 1, 'name' => 'rioxxterms:version_of_record'})
  ]
end

class RcukRioxxValidator < BaseValidator
  @validation_scheme_id = 'RCUK-RIOXX'
  @validation_scheme_description = 'RCUK RIOXX scheme for reporting of open access publications funded through UK Research Council grants'
  
  @properties = [
    RioxxFreeToReadProperty.new({'min' => 0, 'max' => 1}),
    RioxxLicenseRefProperty.new({'min' => 1, 'max' => nil}),
    RioxxStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:coverage'}),
    RioxxStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:description'}),
    RioxxMimeStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:format'}),
    RioxxHttpUriStringProperty.new( {'min' => 1, 'max' => 1, 'name' => 'dc:identifier'}),
    RioxxLanguageStringProperty.new({'min' => 1, 'max' => nil, 'name' => 'dc:language'}),
    RioxxStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:publisher'}),
    RioxxHttpUriStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:relation'}),
    RioxxStringProperty.new({'min' => 0, 'max' => 1, 'name' => 'dc:source'}),#TODO develop a type which checks for recommended ISSNs
    RioxxStringProperty.new({'min' => 0, 'max' => nil, 'name' => 'dc:subject'}),
    RioxxStringProperty.new({'min' => 1, 'max' => 1, 'name' => 'dc:title'}),
    RioxxDateStringProperty.new( {'min' => 1, 'max' => 1, 'name' => 'dcterms:dateAccepted'}),
    RioxxApcProperty.new({'min' => 0, 'max' => 1}),
    RioxxPartyProperty.new({'min' => 1, 'max' => nil, 'name' => 'rioxxterms:author'}),
    RioxxPartyProperty.new({'min' => 0, 'max' => nil, 'name' => 'rioxxterms:contributor'}),
    RioxxProjectProperty.new({'min' => 1, 'max' => nil}),
    RioxxStringProperty.new({'min' => 0, 'max' => 1, 'name' => 'rioxxterms:publication_date'}),
    RioxxItemTypeProperty.new({'min' => 1, 'max' => nil}),
    RioxxVersionProperty.new({'min' => 1, 'max' => 1}),
    RioxxHttpUriStringProperty.new({'min' => 0, 'max' => 1, 'name' => 'rioxxterms:version_of_record'}) 
  ]
end





