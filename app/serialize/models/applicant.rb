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
        'Name' => candidate.name,
        'Role' => application.job.title,
        'Stage' => application.status,
        'Email' => candidate.email,
        'phoneNumber' => candidate.phoneNumber,
        'Hiring_Manager' => application.job.hiringLead,
        'Attachments' => '',
        'Links' => application.attachments.map(&:absolute_path).join(':'),
        'Website' => candidate.websiteUrl,
        'Skills' => '', # TODO
        'Location' => candidate.location,
        'Employment' => '', # TODO
        'Source' => application.applicationReferences,
        'Added' => application.appliedDate,
        'Id' => application.id,
        'CommentsJson' => application.comments_hash.to_json,
        'Status' => application.status,
        'RelPaths' => application.attachments.map(&:relative_path).join(':')
    }
    read_from_hash! hash
  end

  @fields = %I[
    Name Role Stage Email Hiring_Manager Attachments Website Skills Location
    Employment Source Added CommentsJson Links Status RelPaths phoneNumber
  ]

  class << self
    attr_reader :fields
  end

  attr_accessor(*fields)
end
