# frozen_string_literal: true

require 'csv'
require 'json'

require_relative '../array'
require_relative '../hash'

# Base models
class Model
  def read_from_hash!(params)
    hash = params.flatten_labels
    self.class.fields.each do |f|
      writer = (f.to_s + '=').to_s
      send(writer, hash[f.to_s] || '')
    end
  end

  attr_accessor :json

  def to_a
    self.class.fields.map { |field| send(field).to_s }
  end

  def self.header(model)
    model.class.fields.map(&:to_s)
  end

  def self.file_name(model, extension = 'csv')
    "../files/#{model.class.to_s}.#{extension}"
  end

  def self.csv_serialize!(models)
    raise IndexError, "There must be at least 1 model!" if models.empty?

    CSV.open(file_name(models.first), "wb") do |csv|
      csv << header(models.first)
      models.each { |model| csv << model.to_a }
    end
  end
end
