require_relative 'domain'
require 'cocoapods-core'
require_relative "quality_modifiers"

# Setup DB connections
DB.entities.each do |entity|
  name = entity.plural
  define_method name do
    DB[name]
  end
end

# Loop through all Pods
pods.where(:deleted => false).each do |pod|

  # Grab all the usual metadata
  version = pod_versions.where(pod_id: pod.id, deleted: false).sort_by { |v| Pod::Version.new(v.name) }.last
  commit = commits.where(pod_version_id: version.id, deleted_file_during_import: false).first
  next unless pod
  spec = Pod::Specification.from_json commit.specification_data

  metric = cocoadocs_pod_metrics.where(cocoadocs_pod_metrics[:pod_id] => pod.id).first
  next unless metric

  github_stats = github_pod_metrics.where(github_pod_metrics[:pod_id] => pod.id).first
  next unless github_stats

  owners = owners_pods.outer_join(:owners).on(:owner_id => :id).where(:pod_id => pod.id)
  next unless owners

  cocoapods_stats = stats_metrics.where(pod_id: pod.id).first
  # Don't skip if this can't be found, it's not critical

  # Grab the QI
  qi = QualityModifiers.new.generate(spec, metric, github_stats, cocoapods_stats, owners)
  cocoadocs_pod_metrics.update(:quality_estimate => qi).where(id: metric.id).kick.to_json

  # Output to show something is happening
  if metric[:quality_estimate] != qi
    puts "\nMigrated #{pod.name} from #{metric[:quality_estimate]} to #{qi}"
  else
    print "."
  end
end
