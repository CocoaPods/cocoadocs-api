desc "Initializes your working copy to have the correct submodules and gems"
task :bootstrap do
  puts "Updating submodules..."
  `git submodule update --init --recursive`

  puts "Installing gems"
  `bundle install`
end

desc 'Start up the dynamic site'
task :serve do
  sh "foreman start "
end

desc 'Build the static site'
task :build do
  sh "cd middleman && bundle exec middleman build"
end

desc "Deploy to heroku"
task :deploy do
  sh "git push heroku master "
end