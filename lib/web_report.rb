require './lib/model'
require 'yaml'
require 'json'

class WebReport
  
  def initialize(logger)
    @logger = logger
  end
  
  def self.generate_url_and_file_safe_repository_name(repo_name)
    return repo_name.gsub(/[\s\/:,.]/,'_').downcase
  end
  
  def generate_repo_content_files(metadata_format,web_report_content_dir_path)
    begin
      data = Array.new
      metadata_format.repositories.each do |repo|
        repo_hash = Hash.new
        repo_hash['title'] = repo.name
        repo_hash['draft'] = false
        repo_hash['date'] = Time.now.strftime('%Y-%m-%dT%H:%M:%S%:z')
        repo_hash['base_url'] = repo.base_url.to_s
        repo_hash['opendoar_id'] = repo.id
        repo_hash['software_name'] = repo.software_name
        repo_hash['software_version'] = repo.software_version
        repo_hash['file_name'] = WebReport.generate_url_and_file_safe_repository_name(repo.name)
        repo_hash['sample_size'] = repo.repository_records.size
        repo_hash['validation_scheme_reports'] = {}
        repo.repository_records.each do |rec|
          rec.validation_events.each do |event|
            ## horrible intervention to get around fact that yaml doens't like hyphens in keys
            validation_scheme_name = event.validation_scheme.id.gsub(/-/,'_')
            if !repo_hash['validation_scheme_reports'].has_key?(validation_scheme_name) then
              repo_hash['validation_scheme_reports'][validation_scheme_name] = Hash.new
              repo_hash['validation_scheme_reports'][validation_scheme_name]['records'] = 0
              repo_hash['validation_scheme_reports'][validation_scheme_name]['valid'] = 0
            end
            repo_hash['validation_scheme_reports'][validation_scheme_name]['records'] += 1
            if event.valid then
              repo_hash['validation_scheme_reports'][validation_scheme_name]['valid'] += 1
            end
          end
        end
        repo_hash['validation_scheme_reports'].each_value do |validation_scheme_report|
          validation_scheme_report['percentage_valid'] = (validation_scheme_report['valid'].to_f / validation_scheme_report['records'].to_f * 100.0).round(0)
        end
        content_file = File.open("#{web_report_content_dir_path}/#{WebReport.generate_url_and_file_safe_repository_name(repo.name)}.md",'w') do |content_file|
          content_file.write repo_hash.to_yaml
          content_file.puts "---"
          content_file.puts ""
        end
        @logger.debug("Wrote web report content file for '#{repo.name}'")
        data << repo_hash
      end
    rescue Exception => e
      @logger.error(e)
    end  
  end
  
  def generate_report_data_for_repo(repo,web_report_data_dir_path)
    output_file = nil
    begin
      data = Hash.new
      data['name'] = repo.name
      data['base_url'] = repo.base_url.to_s
      data['records'] = Array.new
      if repo.repository_records.size > 0 then
        # data['harvest_datestamp'] = repo.repository_records.first.datestamp.strftime('%Y-%m-%d')
        data['harvest_datestamp'] = repo.harvested.strftime('%Y-%m-%d')
        repo.repository_records.each do |repo_record|
          record = Hash.new
          record['id'] = repo_record.id
          record['datestamp'] = repo_record.datestamp.strftime('%Y-%m-%d')
          record['validation_events'] = Array.new
          if !repo_record.deleted then
            repo_record.validation_events.each do |validation_event|
              ve_hash = {'validation_scheme' => validation_event.validation_scheme_id}
              ve_hash['description'] = validation_event.validation_scheme.description
              ve_hash['valid'] = validation_event.valid
              if !validation_event.valid then
                ve_hash['errors'] = Array.new
                validation_event.issues.each do |issue|
                  ve_hash['errors'] << {'property' => issue.property_name,'message' => issue.message}
                end
              end
              record['validation_events'] << ve_hash
            end
          end
          record['xml'] = repo_record.xml
          data['records'] << record
        end
      else
        data['harvest_datestamp'] = Time.now.strftime('%Y-%m-%d')
      end
      # data_file = File.open("#{web_report_data_dir_path}/#{repo.id}.yaml",'w')
      data_file = File.open("#{web_report_data_dir_path}/#{WebReport.generate_url_and_file_safe_repository_name(repo.name)}.json",'w')
      data_file.write data.to_json
      @logger.debug("Wrote web report data file for '#{repo.name}'")
    rescue Exception => e
      @logger.error(e)
    ensure
      data_file.close unless (data_file == nil || data_file.closed?)
    end
  end
  
  def generate_universal_validation_summary_by_property(universal_validation_summary_by_property_report_file_path)
    props = RcukRioxxValidator.get_properties
    output_file = nil
    data = Array.new
    begin
      props.each do |prop|
        prop_hash = Hash.new
        prop_hash['name'] = prop.name
        issues = Array.new
        issues_for_this_prop = Issue.all(:property_name => prop.name,:fields => [:property_name,:issue_type], :unique => true)
        issue_count_total = 0
        issues_for_this_prop.each do |issue|
          issue_count = Issue.all(:property_name => prop.name,:issue_type => issue.issue_type).count
          # puts "#{prop.name}: #{issue.issue_type} : #{issue_count}"
          issue_count_total += issue_count
          issues << {'type' => issue.issue_type,'count' => issue_count}
        end
        prop_hash['issue_count_total'] = issue_count_total
        prop_hash['issues'] = issues
        data << prop_hash
      end
      output_file = File.open(universal_validation_summary_by_property_report_file_path,'w')
      output_file.write data.to_json
    rescue Exception => e
      @logger.error(e)
    ensure
      output_file.close unless (output_file == nil || output_file.closed?)
    end  
  end
  
end

