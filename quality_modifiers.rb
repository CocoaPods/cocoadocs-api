class Modifier
  attr_accessor :description, :title, :modifier, :function

  def initialize(title, description, modifier, function)
    @title = title
    @description = description
    @modifier = modifier
    @function = function
  end

  def to_json(hash, pod_stats)
    {
      "title" => title,
      "description" => description,
      "modifier" => modifier,
      "applies_for_pod" => function.call(hash, pod_stats)
    }
  end

end

class QualityModifiers

  def generate hash, github_stats
    modify_value = 50
    modifiers.each do |modifier|
      modify_value += modifier.function.call(hash, github_stats) ? modifier.modifier : 0
    end
    modify_value
  end

  def modifiers
    [
      Modifier.new("Test Expectations / Line of Code", "", -20, Proc.new { |hash, stats|
        0.045 < hash[:total_test_expectations].to_i / hash[:total_lines_of_code].to_i
      }),

      Modifier.new("Download size", "", -10, Proc.new { |hash, stats|
        hash[:download_size].to_i > 10000
      }),

      Modifier.new("Lines of Code / File", "", -8, Proc.new { |hash, stats|
        hash[:total_lines_of_code].to_i / hash[:total_files].to_i > 250
      }),

      Modifier.new("Great Documentation", "", 3, Proc.new { |hash, stats|
        hash[:doc_percent].to_i > 90
      }),

      Modifier.new("Documentation", "", 2, Proc.new { |hash, stats|
        hash[:doc_percent].to_i > 60
      }),

      Modifier.new("Badly Documented", "", -8, Proc.new { |hash, stats|
        hash[:doc_percent].to_i < 20
      }),

      Modifier.new("Empty README", "", -8, Proc.new { |hash, stats|
        hash[:readme_complexity].to_i < 20
      }),

      Modifier.new("Minimal README", "", -5, Proc.new { |hash, stats|
        hash[:readme_complexity].to_i < 35
      }),

      Modifier.new("Great README", "", 5, Proc.new { |hash, stats|
        hash[:readme_complexity].to_i > 75
      }),

      Modifier.new("Built in Swift", "", 5, Proc.new { |hash, stats|
        hash[:dominant_langauge] == "Swift"
      }),

      Modifier.new("Built in Objective-C++", "", -5, Proc.new { |hash, stats|
        hash[:dominant_langauge] == "Objective-C++"
      }),

      Modifier.new("Uses GPL", "", -20, Proc.new { |hash, stats|
        hash[:license_short_name] == "GPL 3"
      }),

      Modifier.new("Uses LGPL", "", -10, Proc.new { |hash, stats|
        hash[:license_short_name] == "LGPL 3"
      }),

      Modifier.new("Uses custom License", "", -3, Proc.new { |hash, stats|
        hash[:license_short_name] == "WTFPL" || hash[:license_short_name] == "Custom"
      }),

      Modifier.new("Lots of open issues", "", -8, Proc.new { |hash, stats|
        stats[:open_issues].to_i > 50
      }),

      Modifier.new("Is very popular", "", 30, Proc.new { |hash, stats|
        value = stats[:contributors].to_i * 90 +  stats[:subscribers].to_i * 20 +  stats[:forks].to_i * 10 + stats[:stargazers].to_i
        value > 9000
      }),

      Modifier.new("Is popular", "", 5, Proc.new { |hash, stats|
        value = stats[:contributors].to_i * 90 +  stats[:subscribers].to_i * 20 +  stats[:forks].to_i * 10 + stats[:stargazers].to_i
        value > 1500
      })
    ]
  end
end
