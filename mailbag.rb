# frozen_string_literal: true

require 'date'
require 'json'
require 'mail' # ruby mail library. https://github.com/mikel/mail
require 'rest-client'

# Location of json configuration file
conf = JSON.parse(File.read('/run/secrets/mailbag.json'))

# Generate values for some of the header fields
def header_maker(hdr, kjob, e_date)
  datey = Time.now.strftime('%Y/%m/%d')
  hdr['file_name'] = kjob + '_' + datey + '.xlsx'
  hdr['message_date'] = e_date.to_s
  hdr
end

# configure delivery and retrieval methods
Mail.defaults do
  retriever_method :imap, address: conf['email_host']['host_addr'],
                          port: 993,
                          user_name: conf['email_host']['email_user'],
                          password: conf['email_host']['email_pass'],
                          enable_ssl: true
end

# Iterate over each job defined in json config
conf['mail_jobs'].each do |k, v|
  case v['search'] # Set keys for find according to search type
  when 'sender'    # Email from a specific sender
    emails = Mail.find(keys: ['FROM', v['frommy'], 'SENTON',
                              Time.now.strftime('%d-%b-%Y')])
  when 'subject'   # Email containing a subject keyword
    emails = Mail.find(keys: ['SUBJECT', v['sub_text'], 'SENTSINCE',
                              (Time.now - 86_400).strftime('%d-%b-%Y'),
                              'SENTBEFORE',
                              (Time.now + 86_400).strftime('%d-%b-%Y')])
  else
    next           # Move along if search type is not handled yet
  end

  emails.each do |email| # Iterate over emails found meeting search criteria
    email.attachments.each do |attachment| # Iterate over email attachments
      next unless attachment.content_type.start_with?('application/')

      begin
        headers = header_maker(v['headers'], k, email.date.to_s) # Set headers
        response = RestClient.post v['blob_url'], attachment.decoded, headers
        puts response.code # Push attachment to api endpoint and show code
      rescue StandardError => e
        puts "Unable to post because #{e.message}" # Something went wrong
      end
    end
  end
end
