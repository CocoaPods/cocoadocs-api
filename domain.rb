require 'flounder'
require 'data_objects'

# Handle DB options.
#
options = {}
uri = DataObjects::URI::parse(ENV['DATABASE_URL'])
[:host, :port, :user, :password].each do |key|
  val = uri.send(key)
  options[key] = val if val
end
options[:dbname] = uri.path[1..-1]

# Connect.
#
connection = Flounder.connect options

# Set up pod domain.
#
DB = Flounder.domain connection do |dom|
  # Trunk
  #
  dom.entity :pods, :pod, 'pods'
  dom.entity :owners, :owner, 'owners'
  dom.entity :commits, :commit, 'commits'
  dom.entity :pod_versions, :pod_version, 'pod_versions'
  dom.entity :owners_pods, :owners_pod, 'owners_pods'

  # CocoaDocs
  #
  dom.entity :cocoadocs_pod_metrics, :cocoadocs_pod_metric, 'cocoadocs_pod_metrics'
  dom.entity :github_pod_metrics, :github_pod_metric, 'github_pod_metrics'
  dom.entity :stats_metrics, :stat_metric, 'stats_metrics'
end
