class Modifier
  attr_accessor :description, :title, :modifier, :function
  
  def initialize(title, description, modifier, function)
    @title = title
    @description = description
    @modifier = modifier
    @function = function
  end
  
end

class QualityModifiers
  
  def generate hash    
    modify_value = 0
    modifiers.reduce do |value, modifier|
      value += modifier.function.call(hash) ? modifier.modifier : 0 
    end
  end
  
  def modifiers
    [ 
      Modifier.new("Test Expectations / Line of Code", "", -20, Proc.new { |hash|
        0.045 < hash[:total_test_expectations].to_i / hash[:total_lines_of_code].to_i
      }),

      Modifier.new("Download size", "", -10, Proc.new { |hash|
        hash[:download_size].to_i > 10000
      }),

      Modifier.new("Lines of Code / File", "", -8, Proc.new { |hash|
        hash[:total_lines_of_code].to_i / hash[:total_files].to_i > 250
      }),
    
      Modifier.new("Great Documentation", "", 3, Proc.new { |hash|
        hash[:doc_percent].to_i > 90
      }),
    
      Modifier.new("Documentation", "", 2, Proc.new { |hash|
        hash[:doc_percent].to_i > 60
      }),
    
      Modifier.new("Badly Documentated", "", -8, Proc.new { |hash|
        hash[:doc_percent].to_i < 20
      }),
    
      Modifier.new("Empty README", "", -8, Proc.new { |hash|
        hash[:readme_complexity].to_i < 20
      }),

      Modifier.new("Minimal README", "", -5, Proc.new { |hash|
        hash[:readme_complexity].to_i < 35
      }),
    
      Modifier.new("Minimal README", "", 5, Proc.new { |hash|
        hash[:readme_complexity].to_i > 75
      }),
    
      Modifier.new("Built in Swift", "", 5, Proc.new { |hash|
        hash[:dominant_langauge] == "Swift"
      }),
    
      Modifier.new("Built in Objective-C++", "", -5, Proc.new { |hash|
        hash[:dominant_langauge] == "Objective-C++"
      }),
      
      Modifier.new("Uses GPL", "", -20, Proc.new { |hash|
        hash[:license_short_name] == "GPL"
      }),
    
      Modifier.new("Uses LGPL", "", -10, Proc.new { |hash|
        hash[:license_short_name] == "LGPL"
      }),
      
      # Modifier.new("Uses custom License", "", -3, Proc.new { |hash|
      #   hash[:license_short_name] == ""
      # }),
      
      # Modifier.new("CI Exists", "", -10, Proc.new { |hash|
      #   hash[:license_short_name] == "LGPL"
      # }),
    ]
  end
  
end