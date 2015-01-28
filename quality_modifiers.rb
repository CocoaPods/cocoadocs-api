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
  
  def modifiers
    expect_over_code = Modifier.new "Test Expectations / Line of Code", "", -20, Proc.new { |hash|
      return 0.045 < hash[:total_test_expectations] / hash[:total_lines_of_code]
    }

    [expect_over_code]
  end
  
end