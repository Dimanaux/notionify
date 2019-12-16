# frozen_string_literal: true

# Flattens labels
class Hash
  def flatten_labels
    transform_values do |value|
      if !value.is_a? Hash
        value
      elsif value.key? 'label'
        value['label']
      else
        value.flatten_labels
      end
    end
  end
end
