# frozen_string_literal: true

require 'fileutils'

require_relative 'model'

#
class Attachment < Model
  def initialize(hash)
    read_from_hash!(hash)
    self.content = hash['content']
    self.application.attachments << self
  end

  def write!
    self.dir = File.expand_path("../../../files/#{applicationId}", File.dirname(__FILE__))
    FileUtils.mkdir_p dir
    self.extension = name.split('.').last
    self.file_name = "#{dir}/#{id}.#{extension}"
    self.relative_path = "./files/#{self.applicationId}/#{id}.#{extension}"
    self.absolute_path = File.expand_path(self.file_name)
    File.write(self.absolute_path, content, mode: "wb+")
  end

  def to_s
    "<Attachment##{id} #{type}>"
  end

  @fields = %I[
    file_name application
    id applicationId name type length
    dir extension absolute_path relative_path
  ]

  class << self
    attr_reader :fields
  end

  attr_accessor(*fields)
  attr_accessor :content
end
