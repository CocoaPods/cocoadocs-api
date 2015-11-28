class Modifier
  attr_accessor :description, :title, :modifier, :function

  def initialize(title, description, modifier, function)
    @title = title
    @description = description
    @modifier = modifier
    @function = function
  end

  def to_json(hash, pod_stats, owners)
    {
      "title" => title,
      "description" => description,
      "modifier" => modifier,
      "applies_for_pod" => function.call(hash, pod_stats, owners)
    }
  end

end

class QualityModifiers

  def generate hash, github_stats, owners
    modify_value = 50
    modifiers.each do |modifier|
      modify_value += modifier.function.call(hash, github_stats, owners) ? modifier.modifier : 0
    end
    modify_value
  end

  ### The CocoaPods Guide uses this function with inline markdown to create documentation
  ### around the metrics, so be cautious. The Guides will remove the first character
  ### from every line after the start.

  def modifiers
    [
      #### <---- Start of Markdown

# After the submission of a Podspec to [Trunk](making/getting-setup-with-trunk.html), the documentation service CocoaDocs
# generates a collection of metrics for the Pod. You can look these metrics for any Pod on [metrics.cocoapods.org/api/v1/pods/[Pod]](http://metrics.cocoapods.org/api/v1/pods/ORStackView).
# These metrics are used to generate a variety of Quality Modifiers which eventually turns into a single number called the Quality Index.

# This document is a form of [literate programming](https://en.wikipedia.org/wiki/Literate_programming#cite_note-19)
# within the [CocoaDocs-API](https://github.com/CocoaPods/cocoadocs-api/blob/master/quality_modifiers.rb).
# As such it contains the actual ruby code that is ran in order to generate the individual scores. Plus, Swift looks like Ruby anyway - so you can read it ;).

# The aim of the Quality Index is to highlight postive metrics, and downplay the negative. It is very possible to have a Pod for which no modifier is actually applied. Meaning the Index stays at the default number of 50.
# This is a pretty reasonable score.
#
# A good example of the mentality we have towards the modifiers is to think of a Pod with a majority of it's code in Swift.
# It gets a boost, while an Objective-C one doesn't get modified. It's not about reducing points for Objective-C, but highlighting that right now a Swift library represents forward thinking best practices.

# Finally, before we get started. These metrics are not set in stone, they have been evolving since their unveiling and will continue to do so in the future. Feedback is appreciated, ideally in [issues](https://github.com/CocoaPods/cocoapods.org/issues/new) - so they can be discussed.

### Popularity Metrics

# It's a pretty safe bet that an extremely popular library is going to be a well looked after, and maintained library. We weighed different metrics according to how much more valuable the individual metric is rather than just using stars as the core metric.

      Modifier.new("Very Popular", "The popularity of a project is a useful way of discovering if it is useful, and well maintained.", 30, Proc.new { |hash, stats, owners|
        value = stats[:contributors].to_i * 90 +  stats[:subscribers].to_i * 20 +  stats[:forks].to_i * 10 + stats[:stargazers].to_i
        value > 9000
      }),

# However, not every idea needs to be big enough to warrent such high metrics. A high amount of engagement is useful in it's own right.

      Modifier.new("Popular", "A popular library means there can be a community to help improve and maintain a project.", 10, Proc.new { |hash, stats, owners|
        value = stats[:contributors].to_i * 90 +  stats[:subscribers].to_i * 20 +  stats[:forks].to_i * 10 + stats[:stargazers].to_i
        value > 1500
      }),

# At the moment this is entirely focused on libraries that are coming from GitHub. In the future, once Stats for downloads/installs are mature then we will move over to that in order to accomodate libraries not using GitHub.

### Inline Documentation
# A lot of the generated documentation comes from inside the library itself.
# These metrics are about the usage of [Appledoc](http://nshipster.com/documentation/) and [Headerdoc](http://nshipster.com/swift-documentation/) within your public API.
# This means either from the parts of Swift that you have classed as `public` or from the public headers.
#
# Xcode uses this documentation to give inline hints, and CocoaDocs will create online documentation
# based on this documentation. Making it much easier for anyone using your library to work with.

      Modifier.new("Great Documentation", "A full suite of documentation makes it easier to use a library.", 3, Proc.new { |hash, stats, owners|
        hash[:doc_percent].to_i > 90
      }),

      Modifier.new("Documentation", "A well documented library makes it easier to understand what's going on.", 2, Proc.new { |hash, stats, owners|
        hash[:doc_percent].to_i > 60
      }),

# Providing no inline comments can make it tough for people to work with your code without having to juggle
# between multiple contexts.

      Modifier.new("Badly Documented", "Small amounts of documentation generally means the project is immature.", -8, Proc.new { |hash, stats, owners|
        hash[:doc_percent].to_i < 20
      }),


### README Scoring
# The README score is based on an algorithm that looks at the variety of the *bundled* README.
# You can run the algorithm against any URL here on [scoreme.report](http://scoreme.report).
# A README is the front-page of your library, it can provide an overview of API or show what the
# library can do.
#
# Strange as it sounds, if you are providing a binary CocoaPod, it is worth embedding your README.md
# inside the zip. This means CocoaPods can use it to generate your Pod page. We look for a `README{,.md,.markdown}`
# for two directories from the root of your project.
#
# _Note:_ These modifiers are still in flux a bit, as we want to take a Podspec's `documentation_url` into account.
#

      Modifier.new("Great README", "A well written README gives a lot of context for the library, providing enough information to get started. ", 5, Proc.new { |hash, stats, owners|
        hash[:readme_complexity].to_i > 75
      }),

      Modifier.new("Minimal README", "The README is an overview for a library's API. Providing a minimal README means that it can be hard to understand what the library does.", -5, Proc.new { |hash, stats, owners|
        hash[:readme_complexity].to_i < 40
      }),

      Modifier.new("Empty README", "The README is the front page of a library. To have this applied you may have a very empty README.", -8, Proc.new { |hash, stats, owners|
        hash[:readme_complexity].to_i < 25
      }),

### CHANGELOG
#
# Having a CHANGELOG means that its easier for people for compare older verions, as a metric of quality this generally
# shows a more mature library with care taken by the maintainer to show changes. We look for a `CHANGELOG{,.md,.markdown}`
# for two directories from the root of your project.

      Modifier.new("Has a CHANGELOG", "CHANGELOGs make it easy to see the differences between versions of your library.", 5, Proc.new { |hash, stats, owners|
        hash[:rendered_changelog_url] != nil
      }),

### Language Choices
#
# Swift is slowly happening. We wanted to positively discriminate people writing libraries in Swift.

      Modifier.new("Built in Swift", "Swift is where things are heading.", 5, Proc.new { |hash, stats, owners|
        hash[:dominant_language] == "Swift"
      }),

# Objective-C++ libraries can be difficult to integrate with Swift, and can require a different
# paradigm of programming from what the majority of projects are used to.

      Modifier.new("Built in Objective-C++", "Usage of Objective-C++ makes it difficult for others to contribute.", -5, Proc.new { |hash, stats, owners|
        hash[:dominant_language] == "Objective-C++"
      }),

### Licensing Issues
# The GPL is a legitimate license to use for your code.
# However it is [incompatible](http://www.fsf.org/blogs/licensing/more-about-the-app-store-gpl-enforcement)
# with putting an App on the App Store, which most people would end up doing.
# To protect against this case we detract points from GPL'd libraries.

      Modifier.new("Uses GPL", "There are legal issues around distributing GPL'd code in App Store environments.", -20, Proc.new { |hash, stats, owners|
        hash[:license_short_name] =~ /GPL/i
      }),

# There were also quite a few libraries using the WTFPL, which is a license that aims to not be a license.
# It was rejected by the [OSI](http://opensource.org/) ( An open source licensing body. ) as being no different
# than not including a license.
# If you want to do that, use a [public domain](http://choosealicense.com/licenses/unlicense/) license.

      Modifier.new("Uses WTFPL", "WTFPL was denied as an OSI approved license. Thus it is not classed as code license.", -5, Proc.new { |hash, stats, owners|
        hash[:license_short_name] == "WTFPL"
      }),

### Code Calls
#
# Testing a library is important.
# When you have a library that people are relying on, being able to validate that what you expected to work works increases
# the quality.

      Modifier.new("Has Tests", "Testing a library shows that the developers care about long term quality on a project as internalized logic is made explicit via testing.", 4, Proc.new { |hash, stats, owners|
          hash[:total_test_expectations].to_i > 10
      }),

      Modifier.new("Test Expectations / Line of Code", "Having more code covered by tests is great.", 10, Proc.new { |hash, stats, owners|
        lines = hash[:total_lines_of_code].to_f
        expectations = hash[:total_test_expectations].to_f
        if lines != 0
          0.045 < (expectations / lines)
        else
          false
        end
      }),

# A larger library will increase the size of other people's application. Making them slower to launch.
# CocoaDocs look at the folder size of the library after CocoaPods has removed anything that is not to be integrated in the app.

      Modifier.new("Install size", "Too big of a library (usually caused by media assets) can impact an app's startup time.", -10, Proc.new { |hash, stats, owners|
        hash[:install_size].to_i > 10000
      }),

# CocoaPods makes it easy to create a library with multiple files, we wanted to encourage adoption of smaller
# more composable libraries.

      Modifier.new("Lines of Code / File", "Smaller, more composeable classes tend to be easier to understand.", -8, Proc.new { |hash, stats, owners|
        files = hash[:total_files].to_i
        if files != 0
          (hash[:total_lines_of_code].to_f / hash[:total_files].to_f) > 250
        else
          false
        end
      }),

### Ownership
#
# The CocoaPods Specs Repo isn't curated, and for the larger SDKs people will create un-official Pods.
# We needed a way to state that this Pod has come for the authors of the library, so, we have verified accounts.
# These are useful for the companies the size of; Google, Facebook, Amazon and Dropbox.
# We are applying this very sparingly, and have been reaching out to companies individually.

      Modifier.new("Verified Owner", "When a pod comes from a large company with an official account.", 20, Proc.new { |hash, stats, owners|
        owners.find { |owner| owner.owner.is_verified } != nil
      }),

### Misc - GitHub specific

# This is an experiment in figuring out if a project is abandoned. Issues could be used as a TODO list,
# but leaving 50+ un-opened feels a bit off. It's more likely that the project has been sunsetted.

      Modifier.new("Lots of open issues", "A project with a lot of open issues is generally abandoned. If it is a popular library, then it is usually offset by the popularity modifiers.", -8, Proc.new { |hash, stats, owners|
        stats[:open_issues].to_i > 50
      }),

# This metric checks for frameworks that are genererated when running `xcodebuild` within the downloaded repo. You need to turn on shared schemes for the framework in order for it to be registered.

      Modifier.new("Independently builds through Xcode", "Meaning that the library can independently be built after a git clone.", 5, Proc.new { |hash, stats, owners|
        hash[:builds_independently]
      })

      #### End of Markdown --->
    ]
  end
end
