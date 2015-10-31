# encoding: UTF-8
require 'twitter'

module DefinitelyNotCopiedFromFeedsApp
  # Posts tweets about Pods.
  #
  class TwitterNotifier
    # @return [Twitter::REST::Client]
    #
    attr_accessor :client

    # @param [Twitter::REST::Client] client
    #
    def initialize(client = nil)
      @client = client || default_client
    end

    # @param  [] pod
    #
    # @return [void]
    #
    def tweet(pod)
      status = status_for_pod(pod)
      client.update(status)
    end

    # @return [String]
    #
    def status_for_pod(pod)
      social_media_url = pod.social_media_url
      make_status(pod.name, pod.summary, pod_page_for_pod(pod), social_media_url)
    end

    # Returns the body for the tweet of the given Pod taking into account
    # to truncate the summary.
    #
    # @note   The summary is a required attribute of a Specification.
    #
    # @param  [String] name
    #          The name of the pod
    #
    # @param  [String] summary
    #         The (mandatory) summary of the pod
    #
    # @param  [String] link
    #         The link to the pod page to add at the end of the tweet
    #
    # @param  [String] social_media_url
    #         The Social Media URL (e.g. twitter account) of the pod author
    #
    # @return [String] The body of the tweet.
    #
    def make_status(name, summary, link, social_media_url)
      account = account_for_social_media_url(social_media_url)
      if account
        status = "[#{name} by #{account}] #{summary}"
      else
        status = "[#{name}] #{summary}"
      end
      if status.length > message_max_length
        max_length = message_max_length
        status = truncate_message(status, max_length, ELLIPSIS_STRING)
      end
      status << LINK_SEPARATOR_STRING
      status << link
      status
    end

    def account_for_social_media_url(url)
      return nil unless url
      reg_ex = %r{\Ahttps?://twitter.com/([^/]+)\z}
      match_data = reg_ex.match(url)
      "@#{match_data[1]}" if match_data
    end

    private

    # Private Helpers
    #-------------------------------------------------------------------------#

    # Truncates the given message to the given length using the given ellipsis
    # string. Trailing whitespace, comas and punctuation is removed.
    #
    # @param  [String] message
    #         The message to truncate.
    #
    # @param  [Fixnum] length
    #         The length to which truncate the message, including the ellipsis
    #         string length.
    #
    # @param  [String] ellipsis_string
    #         The ellipsis string to append after the truncated message.
    #
    # @return [String] The truncated message.
    #
    def truncate_message(message, length, ellipsis_string)
      chars = message.scan(/./mu)
      max_length_with_ellipsis = length - ellipsis_string.length - 1
      allowed_chars = chars[0..max_length_with_ellipsis]
      allowed_chars.join.gsub(/ ?\.?,?$/, '') + ellipsis_string
    end

    # @return [Fixnum] The maximum length of the message for the tweet.
    #
    def message_max_length
      MESSAGE_MAX_LENGTH - LINK_MAX_LENGTH - LINK_SEPARATOR_STRING.length
    end

    # @return [String] The pod page URL for the given pod
    def pod_page_for_pod(pod)
      "https://cocoapods.org/pods/#{pod.name}"
    end

    private

    # @return [Twitter::REST::Client]
    #
    def default_client
      Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
        config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
        config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
        config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
      end
    end

    # Constants
    #-------------------------------------------------------------------------#

    # @return [Fixnum] The maximum length of the message.
    #
    MESSAGE_MAX_LENGTH = 140

    # @return [Fixnum] The maximum length of a link. Twitter shortens http urls
    # to 20 characters and https ones to 21.
    #
    LINK_MAX_LENGTH = 21

    # @return [String] The string to use for the ellipsis.
    #
    LINK_SEPARATOR_STRING = ' '

    # @return [String] The string to use for the ellipsis.
    #
    ELLIPSIS_STRING = '…'

    #-------------------------------------------------------------------------#
  end
end
