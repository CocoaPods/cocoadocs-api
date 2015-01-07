require 'sinatra/base'
require 'json'
require 'net/http'

class App < Sinatra::Base
  
  # Set up dynamic part.
  #
  require_relative 'domain'
  
  # Methods for the dynamic part.
  #
  DB.entities.each do |entity|
    name = entity.plural
    define_method name do
      DB[name]
    end
  end
  
  # Gets a Pod Page
  #
  post '/pod/:name' do
    STDOUT.sync = true
    
    # validate IP address against CP server?

    pod = pods.where(pods[:name] => params[:name]).first    
    if pod
      
      data = {
        :pod_id => pod.id,
        :total_files => params["total_files"],
        :total_comments => params["total_comments"],
        :total_lines_of_code => params["total_lines_of_code"],
        :doc_percent => params["doc_percent"],
        :readme_complexity => params["readme_complexity"],
        :rendered_readme_url => params["rendered_readme_url"],
        :initial_commit_date => params["initial_commit_date"],
        :rendered_readme_url => params["rendered_readme_url"],
        :not_found => 0,
        :updated_at => Time.new,
        :download_size => params["download_size"],
        :license_short => params["license_short"],
        :license_link => params["license_link"],
      }
      
      metric = cocoadocs_pod_metrics.where(cocoadocs_pod_metrics[:pod_id] => pod.id).first
      if metric
        puts "found"
        
        # TODO: Updates
        
        # data[:id] = metric.id
        # cocoadocs_pod_metrics.update(data).kick.to_json
        metric.update(data).kick.to_json
      else
        puts "not found"
        data[:created_at] = Time.new
        cocoadocs_pod_metrics.insert(data).kick.to_json
      end

    else
      halt 401
    end
  end

end
