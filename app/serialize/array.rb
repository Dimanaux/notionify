# frozen_string_literal: true

# Flattens labels
class Array
  def flatten_labels
    map do |value|
      if value.is_a? Hash
        value.flatten_labels
      else
        value
      end
    end
  end
end
