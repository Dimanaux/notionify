# frozen_string_literal: true

require_relative 'model'
require_relative 'candidate'

# represents BambooHR's application
class Application < Model
  def initialize(hash)
    read_from_hash!(hash)
    self.candidate = Candidate.new(hash['applicant'])
    self.job = Job.new(hash['job'])
    self.comments = []
    self.attachments = []
  end

  def comments_hash
    {comments: comments.map(&:to_h)}
  end

  @fields = %I[
    id appliedDate status
    rating applicationReferences desiredSalary
    resumeFileId coverLetterFileId
    job candidate comments
    attachments
  ]

  class << self
    attr_reader :fields
  end

  attr_accessor(*fields)
end
