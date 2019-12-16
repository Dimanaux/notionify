# frozen_string_literal: true

require_relative 'model'

# Candidate represents BambooHR's potential employee
class Candidate < Model
  def initialize(hash)
    read_from_hash!(hash)
    self.city = address['city']
    self.state = address['state']
    self.country = address['country']
    self.address = address['addressLine1']
    self.education = "#{education['level']}, #{education['institution']}"
  end

  def to_s
    "<Candidate##{id} #{firstName} #{lastName}>"
  end

  def name
    "#{firstName} #{lastName}"
  end

  def location
    if city && country
      "#{city}, #{country}"
    elsif city
      city
    elsif address
      address
    end
  end

  @fields = %I[
    id firstName lastName email phoneNumber
    address city state country
    linkedinUrl twitterUsername websiteUrl
    availableStartDate education
  ]

  class << self
    attr_reader :fields
  end

  attr_accessor(*fields)
end
