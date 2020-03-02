# frozen_string_literal: true

require 'date'
require 'json'
require 'mail' # ruby mail library. https://github.com/mikel/mail
require 'rest-client'

# Location of json configuration file
conf = JSON.parse(File.read('/run/secrets/mailbag.json'))

# configure delivery and retrieval methods
Mail.defaults do
  retriever_method :imap, address: conf['email_host']['host_addr'],
                          port: 993,
                          user_name: conf['email_host']['email_user'],
                          password: conf['email_host']['email_pass'],
                          enable_ssl: true
end

conf['mail_jobs'].each do |k, v|
  # retrieve messages - search for sender
  case v['search']
  when 'sender'
    emails = Mail.find(keys: ['FROM', v['po_from'], 'SENTON',
                              Time.now.strftime('%d-%b-%Y')])
  when 'subject'
    emails = Mail.find(keys: ['SUBJECT', v['sub_text']], count: 2, what: 'last')
  else
    'Error: Unknown search criteria'
  end

  # loop thru all emails
  emails.each do |email|
    #  push attachments to database api endpoint
    email.attachments.each do |attachment|
      next unless attachment.content_type.start_with?('application/')

      begin
        datey = Time.now.strftime('%Y/%m/%d')
        headers = v['headers']
        headers['file_name'] = k + '_' + datey + '.xlsx'
        headers['message_date'] = email.date.to_s
        response = RestClient.post v['blob_url'], attachment.decoded, headers
        puts response.code
      rescue StandardError => e
        puts "Unable to post #{filename} because #{e.message}"
      end
    end
  end
end
