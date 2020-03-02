require 'date'
require 'json'
require 'mail'  # ruby mail library. https://github.com/mikel/mail
require 'rest-client'

# Location of json configuration file
conf    = JSON.parse(File.read('/run/secrets/mailbag.json'))

# configure delivery and retrieval methods
Mail.defaults do
  retriever_method :imap, :address    => conf['email_host'],
                          :port       => 993,
                          :user_name  => conf['email_user'],
                          :password   => conf['email_pass'],
                          :enable_ssl => true
end

# retrieve messages - search for sender
emails = Mail.find( keys: "FROM " + conf['po_from'], count: 2, what: "last" )

# loop thru all emails and print content
emails.each do |email|

    # Handle attachments
    email.attachments.each do | attachment |
      if (attachment.content_type.start_with?('application/'))
        begin
          datey = Time.now.strftime("%Y/%m/%d")
          headers = conf['headers']
          headers['file_name'] = "po_invoice_" + datey + ".xlsx"
          response = RestClient.post conf['blob_url'], attachment.decoded, headers
        rescue => e
          puts "Unable to post #{filename} because #{e.message}"
        end
      end
    end

end
