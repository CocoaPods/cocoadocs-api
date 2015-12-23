desc "Initializes your working copy to have the correct submodules and gems"
task :bootstrap do
  puts "Updating submodules..."
  `git submodule update --init --recursive`

  puts "Installing gems"
  `bundle install`
end

desc 'Start up the dynamic site'
task :serve do
  sh "bundle exec foreman start"
end

desc "Deploy to heroku"
task :deploy do
  sh "git push heroku master "
end
