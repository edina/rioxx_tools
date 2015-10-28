require 'uri'
require './lib/utilities'

class PropertyValue
  # attr_accessor :content,:attributes
  attr_reader :content,:attributes
  
  def initialize(element)
    @attributes = Hash.new
    @content = element.content
    element.attributes.each do |attribute|
      @attributes[attribute.name] = attribute.value
    end
  end
  
  def get_attribute_value(attribute_name)
    return @attributes[attribute_name]
  end
end

class ValidationError
  attr_accessor :property_name, :error_type, :message, :severity
  
  def initialize(property_name, error_type, message,severity)
    @property_name = property_name
    @error_type = error_type
    @message = message
    @severity = severity
  end
end

class PropertyDataSet
  attr_reader :values,:errors
  
  def initialize
    @values = Array.new
    @errors = Array.new
  end
  
  def add_value(value)
    @values << value
  end
  
  def add_validation_error(error)
    @errors << error
  end
  
  def valid?
    return(@errors.count == 0)
  end
  
  def simple_values_as_array
    string_array = []
    @values.each do |value|
      string_array << value.content
    end
    return string_array
  end
end

class BaseProperty
  attr_reader :name,:min,:max,:data
  
  def initialize(args)
    @valid = false
    @min = args['min']
    @max = args['max']
    @name = args['name']
  end
end

class RioxxBaseProperty < BaseProperty
  RIOXX_NAMESPACES = ['rioxx:http://www.rioxx.net/schema/v2.0/rioxx/','dc:http://purl.org/dc/elements/1.1/','dcterms:http://purl.org/dc/terms/','rioxxterms:http://docs.rioxx.net/schema/v2.0/rioxxterms/','ali:http://ali.niso.org/2014/ali/1.0']
  
  def validate(xml)
    data = PropertyDataSet.new
    if @max == 1 then
      element = find_property_elements_in_xml("//record/metadata/rioxx:rioxx/#{@name}",RIOXX_NAMESPACES,xml,false)
      if element then
        data.add_value(PropertyValue.new(element))
      end
    else
      find_property_elements_in_xml("//record/metadata/rioxx:rioxx/#{@name}",RIOXX_NAMESPACES,xml,true).each do |element|
        if element then
          data.add_value(PropertyValue.new(element))
        end
      end
    end
    if(data.values.length < @min) then
      data.add_validation_error(ValidationError.new(@name, :TOO_FEW_VALUES, "Minimum of #{@min} value(s) required for #{@name} - found #{data.values.length} values",:ERROR))
    end
    if (@max != nil && data.values.length > @max) then
      data.add_validation_error(ValidationError.new(@name, :TOO_MANY_VALUES, "Maximum of #{@max} value(s) required for #{@name} - found #{data.values.length} values",:ERROR))
    end
    return data
  end  
end

class RioxxStringProperty < RioxxBaseProperty
  def validate(xml)
    data = super(xml)
    if !(check_all_strings_exist(data.simple_values_as_array)) then
      data.add_validation_error(ValidationError.new(@name, :EMPTY_STRING_VALUES, "Empty string value(s) found in #{@name}",:ERROR))
    end
    return data
  end
end

class RioxxHttpUriStringProperty < RioxxStringProperty
  def validate(xml)
    data = super(xml)
    data.values.each do |value|
      if(!check_string_is_http_uri(value.content)) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_HTTP_URI, "'#{value.content}' is not a valid HTTP URI in #{@name}",:ERROR))
      end
    end
    return data
  end
end

class RioxxDateStringProperty < RioxxStringProperty
  def validate(xml)
    data = super(xml)
    data.values.each do |value|
      if(!check_string_is_iso8601_date(value.content)) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_ISO8601_DATE, "'#{value}' is not in valid ISO8601 ('yyyy-mm-dd') format in #{@name}",:ERROR))
      end
    end
    return data
  end
end

class RioxxMimeStringProperty < RioxxStringProperty
  def validate(xml)
    data = super(xml)
    data.values.each do |value|
      if(!check_string_is_mime_type(value.content)) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_MIME_TYPE, "This is not a recognised MIME Type in #{@name}",:WARN))
      end
    end
    return data
  end
end

class RioxxLanguageStringProperty < RioxxStringProperty
  def validate(xml)
    data = super(xml)
    data.values.each do |value|
      if(!check_string_is_iso639_3_language_code(value.content)) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_ISO639_3_LANGUAGE_CODE, "'#{value}' is not a recognised ISO639-3 language code in #{@name}",:WARN))
      end
    end
    return data
  end
end

class RioxxFreeToReadProperty < RioxxBaseProperty
  def initialize(args)
    super({'min' => args['min'],'max' => args['max'], 'name' => 'ali:free-to-read'})
  end
  
  def validate(xml)
    data = super(xml)
    data.values.each do |value|
      if value.get_attribute_value('start_date')!=nil && !check_string_is_iso8601_date(value.get_attribute_value('start_date')) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_ISO8601_DATE, "'#{value.get_attribute_value('start_date')}' in the 'start_date' attribute is not in valid ISO8601 ('yyyy-mm-dd') format in #{@name}",:ERROR))
      end
      if value.get_attribute_value('end_date')!=nil && !check_string_is_iso8601_date(value.get_attribute_value('end_date')) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_ISO8601_DATE, "'#{value.get_attribute_value('end_date')}' in the 'end_date' attribute is not in valid ISO8601 ('yyyy-mm-dd') format in #{@name}",:ERROR))
      end
    end
    return data
  end
end

class RioxxLicenseRefProperty < RioxxBaseProperty
  def initialize(args)
    super({'min' => args['min'],'max' => args['max'], 'name' => 'ali:license_ref'})
  end
  
  def validate(xml)
    data = super(xml)
    data.values.each do |value|
      if value.content==nil || !check_string_is_http_uri(value.content) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_HTTP_URI, "'#{value.content}' is not a valid HTTP URI in #{@name}",:ERROR))
      end
      if value.get_attribute_value('start_date')!=nil && !check_string_is_iso8601_date(value.get_attribute_value('start_date')) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_ISO8601_DATE, "'#{value.get_attribute_value('start_date')}' in the 'start_date' attribute is not in valid ISO8601 ('yyyy-mm-dd') format in #{@name}",:ERROR))
      end
    end
    return data
  end
end

class RioxxPartyProperty < RioxxBaseProperty  
  def validate(xml)
    data = super(xml)
    data.values.each do |value|
      if value.get_attribute_value('id') != nil && !check_string_is_http_uri(value.get_attribute_value('id')) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_HTTP_URI, "'#{value.get_attribute_value('id')}' in the 'id' attribute is not a valid HTTP URI in #{@name}",:ERROR))
      end
      if !check_string_exists(value.content) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_NAME, "'#{value.content}' is not a valid name in #{@name}",:WARN))
      end
    end
    return data
  end
end

class RioxxProjectProperty < RioxxBaseProperty
  def initialize(args)
    super({'min' => args['min'],'max' => args['max'], 'name' => 'rioxxterms:project'})
  end
  
  def validate(xml)
    data = super(xml)
    data.values.each do |value|
      if value.get_attribute_value('funder_name') != nil && !check_string_exists(value.get_attribute_value('funder_name')) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_NAME, "'#{value.get_attribute_value('funder_name')}' is not a valid name in #{@name}",:WARN))
      end
      if value.get_attribute_value('funder_id') != nil && !check_string_is_http_uri(value.get_attribute_value('funder_id')) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_HTTP_URI, "'#{value.get_attribute_value('funder_id')}' in the 'funder_id' attributeis not a valid HTTP URI in #{@name}",:ERROR))
      end
      if (value.get_attribute_value('funder_name') == nil && value.get_attribute_value('funder_id') == nil) then
        data.add_validation_error(ValidationError.new(@name, :MISSING_VALUE, "One or both of the attributes 'funder_name' or 'funder_id' must be present in #{@name}",:ERROR))
      end
      if !check_string_exists(value.content) then
        data.add_validation_error(ValidationError.new(@name, :MISSING_VALUE, "'#{value.content}' is not a valid project_id in #{@name}",:ERROR))
      end
    end
    return data
  end
end

class RioxxApcProperty < RioxxBaseProperty
  APC_VOCAB = ['paid','partially waived','fully waived','not charged','not required','unknown'].map(&:downcase)
  def initialize(args)
    super({'min' => args['min'],'max' => args['max'], 'name' => 'rioxxterms:apc'})
  end
  
  def validate(xml)
    data = super(xml)
    data.values.each do |value|
      if(!APC_VOCAB.include?(value.content.downcase)) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_TERM, "'#{value.content}' is not a valid term from the RIOXX APC vocabulary in #{@name}",:WARN))
      end
    end
    return data
  end
end

class RioxxItemTypeProperty < RioxxBaseProperty
  ITEM_TYPE_VOCAB = ['Book','Book chapter','Book edited','Conference Paper/Proceeding/Abstract','Journal Article/Review','Manual/Guide','Monograph','Policy briefing report','Technical Report','Technical Standard','Thesis','Other','Consultancy Report','Working paper'].map(&:downcase)
  
  def initialize(args)
    super({'min' => args['min'],'max' => args['max'], 'name' => 'rioxxterms:type'})
  end
  
  def validate(xml)
    data = super(xml)
    data.values.each do |value|
      if(!ITEM_TYPE_VOCAB.include?(value.content.downcase)) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_TERM, "'#{value.content}' is not a valid term from the RIOXX Item-type vocabulary in #{@name}",:WARN))
      end
    end
    return data
  end
end

class RioxxVersionProperty < RioxxBaseProperty
  VERSION_VOCAB = ['AO','SMUR','AM','P','VoR','CVoR','EVoR','NA'].map(&:downcase)
  
  def initialize(args)
    super({'min' => args['min'],'max' => args['max'], 'name' => 'rioxxterms:version'})
  end
  
  def validate(xml)
    data = super(xml)
    data.values.each do |value|
      if(!VERSION_VOCAB.include?(value.content.downcase)) then
        data.add_validation_error(ValidationError.new(@name, :INVALID_TERM, "'#{value.content}' is not a valid term from the RIOXX Versions vocabulary in #{@name}",:WARN))
      end
    end
    return data
  end
end


