# frozen_string_literal: true

require 'json'
require 'httparty'

# BambooHR API Gateway
class Bamboo
  def initialize(company, api_key)
    self.company = company
    self.api_key = api_key
  end

  def jobs
    get_json('applicant_tracking/jobs')
  end

  def detailed_jobs
    jobs.map { |j| job j['id'] }
  end

  def job(id)
    get_json("applicant_tracking/jobs/#{id}")
  end

  def applications(page_limit = 15)
    applications = []
    1.upto page_limit do |page|
      response = get_json('applicant_tracking/applications', page: page)
      applications += response['applications']
      break if response['paginationComplete']
    end
    applications
  end

  def detailed_applications
    applications.map { |a| application a['id'] }
  end

  def application(id)
    get_json("applicant_tracking/applications/#{id}")
  end

  def application_comments(id)
    get_json("applicant_tracking/applications/#{id}/comments")
  end

  def application_file(application_id, file_id)
    response = get("applicant_tracking/applications/#{application_id}/files/#{file_id}")
    {
        'content' => response.body,
        'name' => response.headers['content-disposition'].split("filename='")[1].split("'")[0],
        'type' => response.headers['content-type'],
        'length' => response.headers['content-length'].to_i,
        'applicationId' => application_id,
        'id' => file_id
    }
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
        }.merge(options[:headers] || {})
    }.merge(options.reject { |k, _| k == :headers })
  end

  def url_for(resource)
    "#{Bamboo.api_gateway}/#{company}/#{Bamboo.api_version}/#{resource}"
  end

  def auth
    {username: api_key, password: 'x'}
  end
end
