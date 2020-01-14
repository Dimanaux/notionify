# frozen_string_literal: true

require_relative 'bamboo'
require_relative 'serialize/models/attachment'
require_relative 'serialize/models/application'
require_relative 'serialize/models/candidate'
require_relative 'serialize/models/comment'
require_relative 'serialize/models/job'
require_relative 'serialize/models/model'
require_relative 'serialize/models/applicant'

def write_file!(file_json)
  attachment = Attachment.new file_json
  attachment.write("../files")
  attachment
end

def main
  bamboo = Bamboo.new(company = '?',
                      api_key = '?')

  jobs_json = bamboo.detailed_jobs
  jobs = jobs_json.map { |j| Job.new(j) }
  Model.csv_serialize! jobs

  applications_json = bamboo.detailed_applications
  applications = applications_json.map { |a| Application.new(a) }
  Model.csv_serialize! applications

  candidates = applications.map(&:candidate)
  Model.csv_serialize! candidates

  comments = Comment.comments bamboo.comments_json(applications)
  Model.csv_serialize! comments

  attachments = bamboo.download_files!(applications)
  Model.csv_serialize! attachments

  applicants = applications.map { |a| Applicant.new(a) }
  Model.csv_serialize! applicants
end

main
