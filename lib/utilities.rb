require 'mime/types'
require 'iso_codes'
require 'xml'

RIOXX_NAMESPACES = ['rioxx:http://www.rioxx.net/schema/v2.0/rioxx/','dc:http://purl.org/dc/elements/1.1/','dcterms:http://purl.org/dc/terms/','rioxxterms:http://docs.rioxx.net/schema/v2.0/rioxxterms/','ali:http://ali.niso.org/2014/ali/1.0']

def find_property_elements_in_xml(xpath,namespace_array,xml,multiple)
  if multiple then
    return xml.find(xpath,namespace_array)
  else
    return xml.find_first(xpath,namespace_array)
  end
end

def check_string_exists(string)
  return(string != nil && string != '')
end

def check_all_strings_exist(string_array)
  result = true
  string_array.each do |string|
    if !check_string_exists(string) then
      result = false
    end
  end
  return result
end

def check_string_is_http_uri(string)
  return((string =~ /\A#{URI::regexp(['http', 'https'])}\z/)==0)
end

def check_string_is_iso8601_date(string)
  y,m,d = string.split '-'
  return(((string =~ /\d{4}-\d{2}-\d{2}/)==0) && (Date.valid_date?(y.to_i, m.to_i, d.to_i)))
end

def check_string_is_mime_type(string)
  return(MIME::Types[string].count > 0)
end

def check_string_is_iso639_3_language_code(string)
  # return(ISOCodes.find_language(string) != nil)
  return true
end

def extract_record_id_from_xml(xml)
  begin
    return xml.find_first('header').find_first('identifier').content
  rescue
    return nil
  end
end