# frozen_string_literal: true

require_relative 'bamboo'
require_relative 'serialize/models/attachment'
require_relative 'serialize/models/application'
require_relative 'serialize/models/candidate'
require_relative 'serialize/models/comment'
require_relative 'serialize/models/job'
require_relative 'serialize/models/model'
require_relative 'serialize/models/applicant'

def comments_json(applications, api)
  comments = []
  applications.each do |a|
    comments_chunk = api.application_comments(a.id)
    replies_chunk = []
    comments_chunk.each do |comment|
      comment['topLevel']['applicationId'] = a.id
      comment['topLevel']['_application'] = a

      if comment['replies']
        comment['replies'].each do |reply|
          reply['applicationId'] = a.id
          reply['_application'] = a
          replies_chunk << reply
        end
      end
    end
    comments += comments_chunk
    comments += replies_chunk.map { |r| { 'topLevel' => r } }
  end
  comments
end

def write_file!(file_json)
  attachment = Attachment.new file_json
  attachment.write("../files")
  attachment
end

def download_files!(applications, api)
  fetch_file = ->(application_id, file_id) do
    if file_id && file_id != ''
      api.application_file(application_id, file_id)
    end
  end

  attachments = []
  applications.each do |a|
    resume = fetch_file[a.id, a.resumeFileId]
    if resume
      resume['application'] = a
      attachments << write_file!(resume)
    end

    cover_letter = fetch_file[a.id, a.coverLetterFileId]
    if cover_letter
      cover_letter['application'] = a
      attachments << write_file!(cover_letter)
    end
  end
  attachments
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

  comments = Comment.comments comments_json(applications, bamboo)
  Model.csv_serialize! comments

  attachments = download_files!(applications, bamboo)
  Model.csv_serialize! attachments

  applicants = applications.map { |a| Applicant.new(a) }
  Model.csv_serialize! applicants
end

main
