# frozen_string_literal: true

require 'date'
require 'json'
require 'mail' # ruby mail library. https://github.com/mikel/mail
require 'rest-client'
require 'timeout'

puts Time.now.strftime('%Y-%m-%d %H:%M:%S') + ' - Mailbag started'

# Location of json configuration file
@conf = JSON.parse(File.read('/run/secrets/mailbag.json'))
@county = 0

def file_name(file, kjob)
  datey = Time.now.strftime('%Y-%m-%d')
  filey = file + '_' + datey + '.xlsx' unless file.nil?
  filey = kjob + '_' + datey + '.xlsx' if file.nil?
  filey
end

def get_attachments(email, kjob, vjob, sender)
  email.attachments.each do |attachment| # Iterate over email attachments
    next unless attachment.content_type.start_with?('application/')

    filey = attachment.filename if kjob == 'market'
    params = [filey, email.date, kjob, sender, email.from[0]]
    headers = h_maker(vjob['headers'], params)
    push_blob(attachment, headers, vjob['blob_url'])
  end
end

# Find email and see if it is new
def get_mail(s_keys, kjob, vjob)
  Mail.find(keys: s_keys) do |email, imap, uid|
    next unless uid > @uids[kjob]['last_uid']

    @county += 1
    @uids[kjob]['last_uid'] = uid
    sender = imap.uid_fetch(uid, 'ENVELOPE')[0].attr['ENVELOPE'].from[0].name
    get_attachments(email, kjob, vjob, sender)
  end
end

# Generate values for some of the header fields
def h_maker(hdr, params)
  hdr['file_name'] = file_name(params[0], params[2])
  hdr['message_date'] = params[1].to_s
  hdr['msg_from_addr'] = params[4]
  hdr['msg_from_name'] = params[3]
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
  puts "Unable to post attachment because #{e.message}" # puts error
end

@results = ''

# Create uid tracking file if missing
init_uid_tracker unless File.exist?(@conf['uid_file'])
@uids = JSON.parse(File.read(@conf['uid_file']))

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
  begin
    Timeout.timeout(120) do
      get_mail(a_keys, k, v)
    end
    @results = ' - Mailbag successful'
  rescue Timeout::Error
    @results = ' - Mailbag failed - Two minute timeout exceeded!'
  end
end

# Update uid tracker
File.open(@conf['uid_file'], 'w') { |f| f.write(JSON.pretty_generate(@uids)) }

# Print results
puts Time.now.strftime('%Y-%m-%d %H:%M:%S') + @results

# Ping monitoring service
loggy = Time.now.strftime('%Y-%m-%d %H:%M:%S') + ' - Pinged monitoring'
headers = @conf['monitoring']['headers']
body = 'attachment_count,app=data_loader,workspace=dco_finmgt value='
body += @county.to_s
response = RestClient.post @conf['monitoring']['url'], body, headers
begin
  puts loggy if response.code >= 200 && response.code <= 204
rescue StandardError => e
  puts "Unable to post to monitor because #{e.message}" # Something went wrong
end

# Clean up mail box - all messages older than 30 days
s_keys = ['SENTBEFORE', (Time.now - (30 * 86_400)).strftime('%d-%b-%Y')]
Mail.find_and_delete(keys: s_keys) do |email, _imap, uid|
  puts 'Delete: ' + uid.to_s + '   ' + email.subject + '   ' + email.date.to_s
end
