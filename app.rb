require 'sinatra/base'
require 'json'
require 'net/http'

class App < Sinatra::Base

  COCOADOCS_IP = ENV['COCOADOCS_IP'] || '199.229.252.196'

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

    # validate IP address against CP server if in production
    if ENV['RACK_ENV'] != "development" && request.ip != COCOADOCS_IP
      halt 401, "You're not CocoaDocs!\n"
    end

    metrics = JSON.load(request.body)

    pod = pods.where(pods[:name] => params[:name]).first
    unless pod
      halt 404, "Pod not found for #{params[:name]}."
    end

    data = {
      :pod_id => pod.id,
      :total_files => metrics["total_files"],
      :total_comments => metrics["total_comments"],
      :total_lines_of_code => metrics["total_lines_of_code"],
      :doc_percent => metrics["doc_percent"],
      :readme_complexity => metrics["readme_complexity"],
      :rendered_readme_url => metrics["rendered_readme_url"],
      :initial_commit_date => metrics["initial_commit_date"],
      :rendered_readme_url => metrics["rendered_readme_url"],
      :not_found => 0,
      :updated_at => Time.new,
      :download_size => metrics["download_size"],
      :license_short_name => metrics["license_short_name"],
      :license_canonical_url => metrics["license_canonical_url"],
    }

    # update or create a metrics
    metric = cocoadocs_pod_metrics.where(cocoadocs_pod_metrics[:pod_id] => pod.id).first
    if metric
      cocoadocs_pod_metrics.update(data).where(id: metric.id).kick.to_json
    else
      data[:created_at] = Time.new
      cocoadocs_pod_metrics.insert(data).kick.to_json
    end

  end
end
