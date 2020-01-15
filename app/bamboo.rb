# frozen_string_literal: true

require 'json'
require 'httparty'
require 'parallel'

# BambooHR API Gateway
class Bamboo
  THREAD_COUNT = 10

  def initialize(company, api_key)
    self.company = company
    self.api_key = api_key
  end

  def jobs
    get_json('applicant_tracking/jobs')
  end

  def detailed_jobs
    jobs.map { |j| j['id'] }
        .sort.uniq
        .map { |id| job id }
  end

  def job(id)
    get_json("applicant_tracking/jobs/#{id}")
  end

  def applications
    applications = []
    page = 1
    loop do
      response = get_json('applicant_tracking/applications', 'page' => page, 'applicationStatus' => 'ALL', 'jobStatusGroups' => 'ALL')
      applications += response['applications']
      break if response['paginationComplete']
      page += 1
    end
    applications
  end

  def detailed_applications
    without_details = applications
    Parallel.map(
        without_details.map { |a| a['id'] }.sort.uniq,
        in_threads: THREAD_COUNT
    ) { |id| application id }
  end

  def application(id)
    get_json("applicant_tracking/applications/#{id}")
  end

  def application_comments(id)
    get_json("applicant_tracking/applications/#{id}/comments") || []
  end

  def comments_json(applications)
    comments = []
    Parallel.each(applications, in_threads: THREAD_COUNT / 4) do |a|
      comments_chunk = application_comments(a.id)
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

  def fetch_file(application_id, file_id)
    if file_id && file_id != ''
      application_file(application_id, file_id)
    end
  end

  def write_file!(file_json)
    attachment = Attachment.new(file_json)
    attachment.write!
    attachment
  end

  def download_files!(applications)
    attachments = []
    Parallel.each(applications, in_threads: THREAD_COUNT) do |a|
      resume = fetch_file(a.id, a.resumeFileId)
      if resume
        resume['application'] = a
        attachments << write_file!(resume)
      end

      cover_letter = fetch_file(a.id, a.coverLetterFileId)
      if cover_letter
        cover_letter['application'] = a
        attachments << write_file!(cover_letter)
      end
    end
    attachments
  end

  def application_file(application_id, file_id)
    response = get("applicant_tracking/applications/#{application_id}/files/#{file_id}")
    result = {
        'content' => response.body,
        'type' => response.headers['content-type'],
        'length' => response.headers['content-length'].to_i,
        'applicationId' => application_id,
        'id' => file_id
    }
    if response.headers['content-disposition']
      result['name'] = response.headers['content-disposition'].split("filename='")[1].split("'")[0]
    elsif response.headers['content-type']
      extension = response.headers['content-type'].split(";")[0].split("/")[1]
      result['name'] = "#{result['name']}.#{extension}"
    end
    result
  end

  private

  @api_version = 'v1'
  @api_gateway = 'https://api.bamboohr.com/api/gateway.php'

  class << self
    attr_reader :api_version, :api_gateway
  end

  attr_accessor :company, :api_key

  def get(path, options = {})
    request(:get, path, options)
  end

  def get_json(path, options = {})
    response = get(path, options)
    JSON.parse(response.body)
  rescue
    tries_left = options.fetch(:tries_left, 3)
    if tries_left > 0
      get_json(path, options.merge(tries_left: tries_left - 1))
    else
      puts path
    end
  end

  def request(method, path, options = {})
    HTTParty.send(
        method, url_for(path),
        default_options(options)
    )
  end

  def default_options(options = {})
    {
        format: :plain,
        basic_auth: auth,
        headers: {
            Accept: 'application/serialize'
        },
        default_params: options
    }.merge(options.reject { |k, _| k == :headers })
  end

  def url_for(resource)
    "#{Bamboo.api_gateway}/#{company}/#{Bamboo.api_version}/#{resource}"
  end

  def auth
    { username: api_key, password: 'x' }
  end
end
