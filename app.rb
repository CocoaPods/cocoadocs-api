require 'sinatra/base'
require 'json'
require 'net/http'
require_relative "quality_modifiers"

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

  # Filter actions for only being ran from CD in prod / testing
  #
  before do
    if ENV['COCOADOCS_SERVER_ONLY'] && ENV['RACK_ENV'] != "development" && request.ip != COCOADOCS_IP
      halt 401, "You're not CocoaDocs!\n"
    end
  end


  # Sets the CocoaDocs metrics for something
  #
  post '/pods/:name' do
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
      :updated_at => Time.new,
      :download_size => metrics["download_size"],
      :license_short_name => metrics["license_short_name"],
      :license_canonical_url => metrics["license_canonical_url"],
      :total_test_expectations => metrics["total_test_expectations"],
      :dominant_language => metrics["dominant_language"],
      :carthage_support => metrics["carthage_support"],
    }

    github_stats = github_pod_metrics.where(github_pod_metrics[:pod_id] => pod.id).first
    owners = owners_pods.outer_join(:owners).on(:owner_id => :id).where(:pod_id => pod.id)
    data[:quality_estimate] = QualityModifiers.new.generate(data, github_stats, owners)

    # update or create a metrics
    metric = cocoadocs_pod_metrics.where(cocoadocs_pod_metrics[:pod_id] => pod.id).first
    if metric
      cocoadocs_pod_metrics.update(data).where(id: metric.id).kick.to_json
    else
      data[:created_at] = Time.new
      cocoadocs_pod_metrics.insert(data).kick.to_json
    end

    metric = cocoadocs_pod_metrics.where(cocoadocs_pod_metrics[:pod_id] => pod.id).first
  end

  get "/" do
    "Hello"
  end

  # Sets the CocoaDocs CLOC metrics for something
  #

  post '/pods/:name/cloc' do
    clocs = JSON.load(request.body)
    pod = pods.where(pods[:name] => params[:name]).first

    unless pod
      halt 404, "Pod not found."
    end

    cloc_metrics = cocoadocs_cloc_metrics
    clocs.map do |cloc_hash|
      cloc_hash[:pod_id] = pod.id
      clocs_db_result = cloc_metrics.where(cloc_metrics[:pod_id] => pod.id, cloc_metrics[:language] => cloc_hash["language"]).first

      if clocs_db_result
        cloc_metrics.update(cloc_hash).where(id: clocs_db_result.id).kick.to_json
      else
        cloc_metrics.insert(cloc_hash).kick.to_json
      end
    end
  end

  # An API route that shows you the reasons why a library scored X
  #

  get '/pods/:name/stats' do
    pod = pods.where(pods[:name] => params[:name]).first
    halt 404, "Pod not found." unless pod

    metric = cocoadocs_pod_metrics.where(cocoadocs_pod_metrics[:pod_id] => pod.id).first
    halt 404, "Metrics for Pod not found." unless metric

    github_stats = github_pod_metrics.where(github_pod_metrics[:pod_id] => pod.id).first
    halt 404, "Github Stats for Pod not found." unless github_stats

    owners = owners_pods.outer_join(:owners).on(:owner_id => :id).where(:pod_id => pod.id)
    halt 404, "Owners for Pod not found." unless owners

    result = {
      base: {
        score: 50,
        description: 'All pods start with 50 points on the quality estimate, ' \
        'we then add or remove to the score based on the following rules'
      }
    }

    result[:metrics] = QualityModifiers.new.modifiers.map do |modifier|
      modifier.to_json(metric, github_stats, owners)
    end

    result.to_json
  end
end
