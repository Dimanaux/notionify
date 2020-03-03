# frozen_string_literal: true

require 'json'

require_relative 'model'
require_relative 'candidate'
require_relative 'application'

# merges application and candidate info
class Applicant < Model
  def initialize(application)
    candidate = application.candidate
    hash = {
        'Id' => application.id,
        'Name' => candidate.name,
        'Role' => application.job.title,
        'Stage' => application.status,
        'Email' => candidate.email,
        'phoneNumber' => candidate.phoneNumber,
        'Hiring_Manager' => application.job.hiringLead,
        'Attachments' => '',
        'Website' => candidate.websiteUrl,
        'Location' => candidate.location,
        'Employment' => '', # TODO
        'Source' => application.applicationReferences,
        'Added' => application.appliedDate,
        'CommentsJson' => application.comments_hash.to_json,
        'RelPaths' => application.attachments.map(&:relative_path).join(':'),
        'rating' => application.rating
    }
    read_from_hash! hash
  end

  @fields = %I[
    Id Name Role Stage Email Hiring_Manager Attachments Website Location
    Added CommentsJson RelPaths phoneNumber rating
  ]

  class << self
    attr_reader :fields
  end

  attr_accessor(*fields)
end
