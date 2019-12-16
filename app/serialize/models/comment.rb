# frozen_string_literal: true

require 'json'

require_relative 'model'

# BambooHR's comment
class Comment < Model
  def initialize(hash)
    read_from_hash!(hash)
    self.id = hash['type']['id']
    self.author = hash['type']['authorUser']['preferredName']
    application = hash['_application']
    self.application = application
    application.comments << self
  end

  def to_h
    {
        id: id,
        author: author,
        text: comment,
        parent_id: parent ? parent : nil,
        date: ymdt
    }
  end

  def self.comments(comments_json = [])
    comments_json
        .map { |j| j['topLevel'] }
        .select { |c| c['type']['type'] == 'comment' }
        .map { |c| Comment.new(c) }
  end

  def to_s
    "<Comment##{id} from #{author}>"
  end

  @fields = %I[
    id applicationId application
    applicant author comment ymdt parent
  ]

  class << self
    attr_reader :fields
  end

  attr_accessor(*fields)
end
