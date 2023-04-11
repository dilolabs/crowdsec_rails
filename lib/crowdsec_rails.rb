# frozen_string_literal: true

require_relative "crowdsec_rails/crowdsec_notifier"
require_relative "crowdsec_rails/middleware"
require_relative "crowdsec_rails/version"

module CrowdsecRails
  class Configuration
    attr_accessor :api_key, :api_url

    def initialize
      @api_key = nil
      @api_url = nil
    end
  end

  def self.configure
    @configuration ||= Configuration.new
    yield(@configuration) if block_given?
    @configuration
  end

  def self.configuration
    @configuration
  end

  class Error < StandardError; end
end
