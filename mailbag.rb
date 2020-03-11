# frozen_string_literal: true

require 'date'
require 'json'
require 'mail' # ruby mail library. https://github.com/mikel/mail
require 'rest-client'

# Location of json configuration file
@conf = JSON.parse(File.read('/run/secrets/mailbag.json'))

def get_attachments(email, kjob, vjob)
  email.attachments.each do |attachment| # Iterate over email attachments
    next unless attachment.content_type.start_with?('application/')

    filey = attachment.filename[/.+?(?=\sMarket)/] if kjob == 'market'
    headers = h_maker(vjob['headers'], filey, email.date.to_s, kjob)
    push_blob(attachment, headers, vjob['blob_url'])
  end
end

# Find email and see if it is new
def get_mail(s_keys, kjob, vjob)
  uids = JSON.parse(File.read(@conf['uid_file']))
  Mail.find(keys: s_keys) do |email, _imap, uid|
    if uid > uids[kjob]['last_uid']
      uids[kjob]['last_uid'] = uid
      get_attachments(email, kjob, vjob)
    end
  end
  File.open(@conf['uid_file'], 'w') { |f| f.write(JSON.pretty_generate(uids)) }
end

# Generate values for some of the header fields
def h_maker(hdr, fname, e_date, kjob)
  datey = Time.now.strftime('%Y/%m/%d')
  hdr['file_name'] = fname + '_' + datey + '.xlsx' unless fname.nil?
  hdr['file_name'] = kjob + '_' + datey + '.xlsx' if fname.nil?
  hdr['message_date'] = e_date
  hdr
end

# Create a uid tracker file
def init_uid_tracker
  uid_saves = {}
  @conf['mail_jobs'].each { |k, _v| uid_saves[k] = { last_uid: 1 } }
  File.open(@conf['uid_file'], 'w') do |f|
    f.write(JSON.pretty_generate(uid_saves))
  end
end

# Push attachment to api endpoint and show code
def push_blob(attachment, headers, url)
  response = RestClient.post url, attachment.decoded, headers
  puts response.code
rescue StandardError => e
  puts "Unable to post because #{e.message}" # Something went wrong
end

# Create uid tracking file if missing
init_uid_tracker unless File.exist?(@conf['uid_file'])

# configure delivery and retrieval methods
server = @conf['email_host']
Mail.defaults do
  retriever_method :imap, address: server['host_addr'],
                          port: 993,
                          user_name: server['email_user'],
                          password: server['email_pass'],
                          enable_ssl: true
end

# Iterate over each job defined in json config
@conf['mail_jobs'].each do |k, v|
  case v['search'] # Set keys for imap search according to search type
  when 'sender'    # Email from a specific sender
    a_keys = ['FROM', v['frommy'], 'SENTON', Time.now.strftime('%d-%b-%Y')]
  when 'subject'   # Email containing a subject keyword
    a_keys = ['SUBJECT', v['sub_text'], 'SENTSINCE',
              (Time.now - 86_400).strftime('%d-%b-%Y'),
              'SENTBEFORE', (Time.now + 86_400).strftime('%d-%b-%Y')]
  else
    next           # Move along if search type is not handled yet
  end
  get_mail(a_keys, k, v)
end
