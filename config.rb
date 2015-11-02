require 'yaml'
require 'logger'
require 'data_mapper'
require './lib/model'


# VALIDATION_SCHEME_NAMES = [
#   {:name=>'RIOXX',:description=>'Base RIOXX scheme designed for low-level interoperability'},
#   {:name=>'RCUK-RIOXX',:description=>'RCUK RIOXX scheme for reporting of open access publications funded through UK Research Council grants'}
# ]

class RioxxCheckerConfigurator
	attr_reader :reset_all_data,:configuration,:data_dir_path,:web_report_data_dir_path,:web_report_content_dir_path,:repo_list_from_opendoar_api_uri,:sample_harvest_size

	def initialize(yaml_file_path,logger)
		@logger = logger
		@configuration = YAML.load_file(yaml_file_path)
		@reset_all_data = @configuration['reset_all_data']
		@data_dir_path = @configuration['data_dir_path']
		@web_report_data_dir_path = @configuration['web_report_data_dir_path']
		@web_report_content_dir_path = @configuration['web_report_content_dir_path']
		@repo_list_from_opendoar_api_uri = @configuration['repo_list_from_opendoar_api_uri']
		@sqlite_db_path = @configuration['sqlite_db_path']
		@sample_harvest_size = @configuration['sample_harvest_size']
		case @configuration['log_level']
		when 'debug'
			@logger.level = Logger::DEBUG
		when 'info'
			@logger.level = Logger::INFO
		when 'warn'
			@logger.level = Logger::WARN
		when 'error'
			@logger.level = Logger::ERROR
		when 'fatal'
			@logger.level = Logger::FATAL
		else
			@logger.level = Logger::INFO
		end
		@logger.debug("Configuration read successfully from file at '#{yaml_file_path}'")
		DataMapper::Logger.new($stdout,@configuration['db_log_level'].to_sym)
		DataMapper::Model.raise_on_save_failure = true
		DataMapper::Property::String.length(255)
		DataMapper.setup(:default,"sqlite://#{@data_dir_path}/rioxx_checker.db")
    DataMapper.finalize
		if @reset_all_data then
			DataMapper.auto_migrate!
		else
			DataMapper.auto_upgrade!
		end
		MetadataFormat.first_or_create(:prefix => 'rioxx', :uri => 'http://www.rioxx.net/schema/v2.0/rioxx')
		@logger.info("Configured successfully with '#{yaml_file_path}'")
	end

	def universal_validation_summary_by_property_report_file_path
		return "#{@web_report_data_dir_path}/universal_validation_summary_by_property.json"
	end

	def repo_check_data_dir_path
		return "#{@web_report_data_dir_path}/repo_checks"
	end



end