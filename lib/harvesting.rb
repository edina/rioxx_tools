require 'oai'
require 'xml'
require './lib/model'
require './lib/utilities'

class OaiHarvester
  
  XML_PARSER = 'libxml'
  
  def initialize(logger)
    @logger = logger
  end
  
  def save_repository_record(record_set,metadata_format,repo,limit,harvest_count)
    record_set.doc.find('//record').each do |rec|
      record_harvested_ok = false
      xml_doc = XML::Document.new
      root_element = xml_doc.import(rec)
      xml_doc.root = root_element
      record_id = extract_record_id_from_xml(xml_doc)
      oai_pmh_record = RepositoryRecord.get(record_id)
      if !oai_pmh_record then
        oai_pmh_record = RepositoryRecord.new
        oai_pmh_record.id = record_id
        oai_pmh_record.metadata_format = metadata_format
        oai_pmh_record.repository_id = repo.id
        oai_pmh_record.xml = xml_doc
        if !oai_pmh_record.deleted then
          oai_pmh_record.save
          record_harvested_ok = true
        end
      else
        #TODO figure out how an update should behave
      end
      if record_harvested_ok then
        harvest_count += 1
        @logger.debug("Harvested record with id = #{oai_pmh_record.id} harvest_count = #{harvest_count}")
      end
      if (limit > 0 && harvest_count > (limit-1)) then
        return harvest_count
      end
    end
    return harvest_count
  end
  
  def harvest(repo,metadata_format,limit,fresh_harvest=true)
    @logger.info("Harvesting #{metadata_format.prefix} records from repo: '#{repo.name}'....")
    begin
      harvest_count = 0
      if(fresh_harvest) then
        repo.repository_records.each do |record|
          record.issues.destroy
          record.destroy
        end
      end
      client = OAI::Client.new(repo.base_url, :parser => XML_PARSER)
      record_set = client.list_records(:metadata_prefix => metadata_format.prefix)
      harvest_count = save_repository_record(record_set,metadata_format,repo,limit,harvest_count)
      resumption_token = record_set.resumption_token
      @logger.debug("Resumption token = #{resumption_token}")
      while resumption_token && (limit == 0 || harvest_count < limit) do
        @logger.debug("Harvest count = #{harvest_count}")
        record_set = client.list_records(:resumption_token => resumption_token)
        harvest_count = save_repository_record(record_set,metadata_format,repo,limit,harvest_count)
        resumption_token = record_set.resumption_token
      end
    rescue Exception => e
      @logger.error(e.message)
    ensure
      repo.harvested = Time.now
      repo.save
      @logger.info("Completed harvest of #{metadata_format.prefix} records from repo: '#{repo.name}'")
    end
  end
  
  def check_metadata_formats_available(repo)
    begin
      @logger.debug("Beginning metadata formats check for repo: '#{repo.name}'....")
      client = OAI::Client.new(repo.base_url, :parser => XML_PARSER)
      response = client.list_metadata_formats
      response.doc.find('//metadataFormat').each do |format_element|
        metadata_format = MetadataFormat.first_or_create(:prefix => format_element.find_first('metadataPrefix').content)
        metadata_format.repositories << repo
        metadata_format.save
        @logger.debug("Repository '#{repo.name}' is enabled for '#{metadata_format.prefix}'")
      end
    rescue Exception => e
      @logger.error(e.message)
      repo.error = true
    ensure
      repo.save
      @logger.debug("Completed check for repo: '#{repo.name}'")
    end
  end
end