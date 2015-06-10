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

  def modifiers
    [
      Modifier.new("Is very popular", "The popularity of a project is a useful way of discovering if it is useful, and well maintained.", 30, Proc.new { |hash, stats, owners|
        value = stats[:contributors].to_i * 90 +  stats[:subscribers].to_i * 20 +  stats[:forks].to_i * 10 + stats[:stargazers].to_i
        value > 9000
      }),

      Modifier.new("Is popular", "A popular library means there can be a community to help improve and maintain a project.", 10, Proc.new { |hash, stats, owners|
        value = stats[:contributors].to_i * 90 +  stats[:subscribers].to_i * 20 +  stats[:forks].to_i * 10 + stats[:stargazers].to_i
        value > 1500
      }),
      
      Modifier.new("Great Documentation", "A full suite of documentation makes it easier to use a library.", 3, Proc.new { |hash, stats, owners|
        hash[:doc_percent].to_i > 90
      }),

      Modifier.new("Documentation", "A well documented library makes it easier to understand what's going on.", 2, Proc.new { |hash, stats, owners|
        hash[:doc_percent].to_i > 60
      }),

      Modifier.new("Badly Documented", "Small amounts of documentation generally means the project is immature.", -8, Proc.new { |hash, stats, owners|
        hash[:doc_percent].to_i < 20
      }),

      Modifier.new("Empty README", "The README is the front page of a library. To have this applied you may have a very empty README.", -8, Proc.new { |hash, stats, owners|
        hash[:readme_complexity].to_i < 25
      }),

      Modifier.new("Minimal README", "The README is an overview for a libraries API. Providing a minimal README means that it can be hard to understand what the library does.", -5, Proc.new { |hash, stats, owners|
        hash[:readme_complexity].to_i < 40
      }),

      Modifier.new("Great README", "A well written README gives a lot of context for the library, providing enough information to get started. ", 5, Proc.new { |hash, stats, owners|
        hash[:readme_complexity].to_i > 75
      }),

      Modifier.new("Built in Swift", "Swift is where things are heading.", 5, Proc.new { |hash, stats, owners|
        hash[:dominant_language] == "Swift"
      }),

      Modifier.new("Built in Objective-C++", "Usage of Objective-C++ makes it difficult for others to contribute.", -5, Proc.new { |hash, stats, owners|
        hash[:dominant_language] == "Objective-C++"
      }),

      Modifier.new("Uses GPL", "There are legal issues around distributing GPL'd code in App Store environments.", -20, Proc.new { |hash, stats, owners|
        hash[:license_short_name] =~ /GPL/i
      }),

      Modifier.new("Uses WTFPL", "WTFPL was denied as an OSI approved license. Thus it is not classed as code license.", -5, Proc.new { |hash, stats, owners|
        hash[:license_short_name] == "WTFPL"
      }),

      Modifier.new("Lots of open issues", "A project with a lot of open issues is generally abandoned. If it is a popular library, then it is usually offset by the popularity modifiers.", -8, Proc.new { |hash, stats, owners|
        stats[:open_issues].to_i > 50
      }),

      Modifier.new("Independently builds through xcode", "Means that the library can independently be built.", 5, Proc.new { |hash, stats, owners|
        hash[:carthage_support]
      }),
      Modifier.new("Test Expectations / Line of Code",
                    "Testing a library shows that the developers care about long term quality on a project as internalized logic is made explicit via testing.", -20, Proc.new { |hash, stats, owners|
        lines = hash[:total_lines_of_code].to_i
        if lines != 0
          0.045 < hash[:total_test_expectations].to_i / lines
        else
          false
        end
      }),

      Modifier.new("Download size", "Too big of a library can impact startup time, and add redundant assets.", -10, Proc.new { |hash, stats, owners|
        hash[:download_size].to_i > 10000
      }),

      Modifier.new("Lines of Code / File", "Smaller, more composeable classes tend to be easier to understand.", -8, Proc.new { |hash, stats, owners|
        files = hash[:total_files].to_i
        if files != 0
          hash[:total_lines_of_code].to_i / hash[:total_files].to_i > 250
        else
          false
        end
      }),

      Modifier.new("Verified Owner", "When a pod comes from a large company with an official account.", 20, Proc.new { |hash, stats, owners|
        owners.find { |owner| owner.owner.is_verified } != nil
      })
    ]
  end
end
