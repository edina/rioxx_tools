require 'xml'
require 'yaml'
require './lib/model'
require './lib/utilities'
require './lib/harvesting'

class Registry
	def initialize(logger)
		@logger = logger
  end
  
  def batch_load_from_opendoar_response(xml_doc,overwrite_registry=true)
    if overwrite_registry then
      Repository.destroy
    end
    count = 0
    xml_doc.find("//repositories/repository").each do |element|
      begin
        repo = Repository.new(:id => element.find_first('@rID').value)
        repo.name = element.find_first('rName').content
        repo.base_url = element.find_first('rOaiBaseUrl').content
        repo.software_name = element.find_first('rSoftWareName').content
        repo.software_version = element.find_first('rSoftWareVersion').content
        repo.save
        @logger.debug("Added repo '#{repo.name}' to registry")
        count += 1
      rescue Exception => e
        @logger.error(e.message)
        next
      end
    end
    @logger.info("Added #{count} repositories to registry from OpenDOAR request")
  end
  
  def all_repos
    return Repository.all
  end
  
  def repos_supporting_metadata_format(metadata_format_prefix)
    return MetadataFormat.get(metadata_format_prefix).repositories
  end
  
end