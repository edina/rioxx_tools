#!/usr/bin/env ruby
require 'oai'
require 'open-uri'
require 'logger'
require 'yaml'
require 'json'
require './lib/model'
require './lib/registry'
require 'data_mapper'
require 'xml'
require './config'
require './lib/validators'
require './lib/properties'
require './lib/web_report'

def populate_registry(config,registry,harvester,logger)
  xml_doc = XML::Parser.string(open(config.repo_list_from_opendoar_api_uri).read).parse;
  logger.info("Loading repo list from OpenDOAR API")
  registry.batch_load_from_opendoar_response(xml_doc,true)
  registry.all_repos.each do |repo|
    harvester.check_metadata_formats_available(repo)
  end
end

def do_harvest(config,registry,harvester,metadata_format)
  registry.repos_supporting_metadata_format(metadata_format.prefix).each do |repo|
    harvester.harvest(repo,metadata_format,config.sample_harvest_size,true)
  end
end

def do_validation(metadata_format,logger)
  Issue.all.destroy
  ValidationEvent.all.destroy
  RepositoryRecord.all(:metadata_format => metadata_format).each do |oai_pmh_record|
    RioxxValidator.validate!(oai_pmh_record,logger)
    RcukRioxxValidator.validate!(oai_pmh_record,logger)
  end
end

def do_web_report(config,registry,metadata_format,logger)
  report = WebReport.new(logger)
  report.generate_repo_content_files(metadata_format,config.web_report_content_dir_path)
  report.generate_universal_validation_summary_by_property(config.universal_validation_summary_by_property_report_file_path)
  registry.repos_supporting_metadata_format(metadata_format.prefix).each do |repo|
    report.generate_report_data_for_repo(repo,config.repo_check_data_dir_path)
  end
end



### MAIN ROUTINE STARTS HERE
logger = Logger.new(STDOUT)
logger.formatter = proc { |severity, datetime, progname, msg|
  "#{severity} #{caller[4]} #{msg}\n"
}
STDOUT.sync = true

config = RioxxCheckerConfigurator.new("#{File.dirname(__FILE__)}/config.yaml",logger)
logger.info("Starting main routine....")

metadata_format = MetadataFormat.get('rioxx')
harvester = OaiHarvester.new(logger)
registry = Registry.new(logger)

### if 'reset_all_data' flag set, get a fresh copy of the registry of repositorioes from OpenDOAR and check each for declared RIOXX support.
if config.reset_all_data then
  populate_registry(config,registry,harvester,logger)
end

### harvest sample set of records from each repository
# do_harvest(config,registry,harvester,metadata_format)

### clear out previous validation data and re-analyse collected sample records
# do_validation(metadata_format,logger)

### generate web reports
do_web_report(config,registry,metadata_format,logger)



