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

  def write(parent_dir_path)
    self.dir = "#{parent_dir_path}/#{applicationId}"
    FileUtils.mkdir_p dir
    self.extension = name.split('.').last
    self.file_name = "#{dir}/#{id}.#{extension}"
    self.absolute_path = File.expand_path(self.file_name)
    File.write(self.absolute_path, content, mode: "wb")
  end

  def to_s
    "<Attachment##{id} #{type}>"
  end

  @fields = %I[
    file_name application
    id applicationId name type length
    dir extension absolute_path
  ]

  class << self
    attr_reader :fields
  end

  attr_accessor(*fields)
  attr_accessor :content
end
