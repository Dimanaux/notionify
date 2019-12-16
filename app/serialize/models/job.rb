# frozen_string_literal: true

require_relative 'model'

# Job represents BambooHR job, can export itself to csv
class Job < Model
  def initialize(hash)
    read_from_hash!(hash)
    lead = hash['hiringLead']
    self.hiringLead = lead['firstName'] + ' ' + lead['lastName']
  end

  def to_s
    "<Job##{id} #{title}>"
  end

  @fields = %I[
    id title status department location postedDate
    hiringLead
    postingUrl
  ]

  class << self
    attr_reader :fields
  end

  attr_accessor(*fields)
end
