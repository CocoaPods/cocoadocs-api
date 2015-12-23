require 'sinatra/base'
require 'json'
require 'net/http'
require 'cocoapods-core'
require_relative "quality_modifiers"
require_relative "twitter_notifier"

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

  # Sets the CocoaDocs metrics for something
  #
  post '/pods/:name' do
    metrics = JSON.load(request.body)

    if ENV['COCOADOCS_TOKEN'] != metrics["token"]
      halt 401, "You're not CocoaDocs!\n"
    end

    pod = pods.where(pods[:name] => params[:name]).first
    unless pod
      halt 404, "Pod not found for #{params[:name]}."
    end

    # Support redirecting to the pods homepage if we can't do it.
    version = pod_versions.where(pod_id: pod.id, deleted: false).sort_by { |v| Pod::Version.new(v.name) }.last
    commit = commits.where(pod_version_id: version.id, deleted_file_during_import: false).first
    spec = Pod::Specification.from_json commit.specification_data

    data = {
      :pod_id => pod.id,
      :total_files => metrics["total_files"],
      :total_comments => metrics["total_comments"],
      :total_lines_of_code => metrics["total_lines_of_code"],
      :doc_percent => metrics["doc_percent"],
      :readme_complexity => metrics["readme_complexity"],
      :rendered_readme_url => metrics["rendered_readme_url"],
      :rendered_summary => metrics["rendered_summary"],
      :rendered_changelog_url => metrics["rendered_changelog_url"],
      :initial_commit_date => metrics["initial_commit_date"],
      :updated_at => Time.new,
      :install_size => metrics["install_size"],
      :license_short_name => metrics["license_short_name"],
      :license_canonical_url => metrics["license_canonical_url"],
      :total_test_expectations => metrics["total_test_expectations"],
      :dominant_language => metrics["dominant_language"],
      :is_vendored_framework => metrics["is_vendored_framework"],
      :builds_independently => metrics["builds_independently"],
      :spm_support => metrics["spm_support"],
    }

    github_stats = github_pod_metrics.where(github_pod_metrics[:pod_id] => pod.id).first
    cocoapods_stats = stats_metrics.where(pod_id: pod.id).first
    owners = owners_pods.outer_join(:owners).on(:owner_id => :id).where(:pod_id => pod.id)
    data[:quality_estimate] = QualityModifiers.new.generate(spec, data, github_stats, cocoapods_stats, owners)

    # update or create a metrics
    metric = cocoadocs_pod_metrics.where(cocoadocs_pod_metrics[:pod_id] => pod.id).first
    if metric
      cocoadocs_pod_metrics.update(data).where(id: metric.id).kick.to_json
    else
      data[:created_at] = Time.new
      cocoadocs_pod_metrics.insert(data).kick.to_json
      tweet_if_needed spec, data[:quality_estimate]
    end

    metric = cocoadocs_pod_metrics.where(cocoadocs_pod_metrics[:pod_id] => pod.id).first
  end

  QUALITY_WORTHY_OF_A_TWEET = 70

  def tweet_if_needed(spec, estimate)
    return if estimate < QUALITY_WORTHY_OF_A_TWEET
    notifier = DefinitelyNotCopiedFromFeedsApp::TwitterNotifier.new()
    notifier.tweet spec
  end

  get "/" do
    "Hello"
  end

  # An API route that shows you the reasons why a library scored X
  #

  get '/pods/:name/stats' do
    pod = pods.where(pods[:name] => params[:name]).first
    halt 404, "Pod not found." unless pod

    version = pod_versions.where(pod_id: pod.id, deleted: false).sort_by { |v| Pod::Version.new(v.name) }.last
    commit = commits.where(pod_version_id: version.id, deleted_file_during_import: false).first
    halt 404, "Commit for latest version not found." unless pod
    spec = Pod::Specification.from_json commit.specification_data

    metric = cocoadocs_pod_metrics.where(cocoadocs_pod_metrics[:pod_id] => pod.id).first
    halt 404, "Metrics for Pod not found." unless metric

    github_stats = github_pod_metrics.where(github_pod_metrics[:pod_id] => pod.id).first
    halt 404, "Github Stats for Pod not found." unless github_stats

    owners = owners_pods.outer_join(:owners).on(:owner_id => :id).where(:pod_id => pod.id)
    halt 404, "Owners for Pod not found." unless owners

    cocoapods_stats = stats_metrics.where(pod_id: pod.id).first
    # Don't 404 if this can't be found, it's not critical

    result = {
      base: {
        score: 50,
        description: 'All pods start with 50 points on the quality estimate, ' \
        'we then add or remove to the score based on the following rules'
      }
    }

    result[:metrics] = QualityModifiers.new.modifiers.map do |modifier|
      modifier.to_json(spec, metric, github_stats, cocoapods_stats, owners)
    end

    result.to_json
  end
end
