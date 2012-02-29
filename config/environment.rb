# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode
# (Use only when you can't set environment variables through your web/app server)
 ENV['RAILS_ENV'] ||= 'development'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

#require 'aws/ses'

#require 'tlsmail'

amazon_creds = YAML::load(open("#{RAILS_ROOT}/config/amazon.yml"))

# extend ActionMailer
#puts "extending ActionMailer for AWS ..."

#ActionMailer::Base.custom_amazon_ses_mailer = AWS::SES::Base.new({
#  :access_key_id => amazon_creds['access_key_id'],
#  :secret_access_key => amazon_creds['secret_access_key']
#})

#require 'net/smtp'

#module Net
#  class SMTP
#    def tls?
#      true
#    end
#  end
#end

Rails::Initializer.run do |config|
  config.action_controller.session = { :key => "_myapp_session", :secret => "the name of this band is talking heads is this 30 characters?" }
  config.logger=nil if ENV['LOGGING']=='no'
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  # config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  config.cache_store = :file_store, "#{RAILS_ROOT}/cache"

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
end

SETTINGS = YAML.load(File.open("#{RAILS_ROOT}/config/settings.yml"))


# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below

#sample SMTP session with amazon
=begin
EHLO ec2-23-20-115-55.compute-1.amazonaws.com
AUTH LOGIN

QUtJQUlGNlhJUEpTVVM1TFBZNFE=

QXRhby93U3RDd0NzbGo1aEJzdERWLzVyZ2xKK3UxOUxPUVBHaGxLL2pUSk4=

MAIL FROM: chris@psychoastronomy.org
RCPT TO: chris@psychoastronomy.org
DATA

test
.

QUIT


=end

# setup mail-server configuration params
if ENV['RAILS_ENV']=='development'
  puts "setup dev mode mail"
    ActionMailer::Base.smtp_settings = {
      :address => "secure.seremeth.com",
      :authentication => :plain,
      :user_name => "chris@psychoastronomy.org",
      :password => "montgomery"
#        :address => "tourfilter.com",
#        :domain => "ruby"
    }
else
  puts "setup production mode mail"
  puts "smtp username:"+amazon_creds['smtp_username']
#  Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.default_charset = "utf-8"
  ActionMailer::Base.default_url_options = { :host => "tourfilter.com"}
  ActionMailer::Base.raise_delivery_errors = true
  ActionMailer::Base.logger = Logger.new("mailer.log")
  ActionMailer::Base.smtp_settings = {
    :address => "email-smtp.us-east-1.amazonaws.com",
    :port =>  465,
    :enable_starttls_auto => true,
#    :domain => "tourfilter.com",
    :authentication =>  :login,
    :user_name => amazon_creds['smtp_username'],
    :password =>  amazon_creds['smtp_password']
  }
  ActionMailer::Base.smtp_settings = {
    :address => "tourfilter.com",
    :domain => "rails"
  }
end

# These defaults are used in GeoKit::Mappable.distance_to and in acts_as_mappable
GeoKit::default_units = :miles
GeoKit::default_formula = :sphere

# This is the timeout value in seconds to be used for calls to the geocoder web
# services.  For no timeout at all, comment out the setting.  The timeout unit
# is in seconds. 
GeoKit::Geocoders::timeout = 3

# These settings are used if web service calls must be routed through a proxy.
# These setting can be nil if not needed, otherwise, addr and port must be 
# filled in at a minimum.  If the proxy requires authentication, the username
# and password can be provided as well.
GeoKit::Geocoders::proxy_addr = nil
GeoKit::Geocoders::proxy_port = nil
GeoKit::Geocoders::proxy_user = nil
GeoKit::Geocoders::proxy_pass = nil

# This is your yahoo application key for the Yahoo Geocoder.
# See http://developer.yahoo.com/faq/index.html#appid
# and http://developer.yahoo.com/maps/rest/V1/geocode.html
GeoKit::Geocoders::yahoo = '_sWonC7V34Fib_GGCLOo3tNSRB1B6000j7pqmGs_ugBCtTGK8MGyNT_qAHR37NrT5bTU9w--'
    
# This is your Google Maps geocoder key. 
# See http://www.google.com/apis/maps/signup.html
# and http://www.google.com/apis/maps/documentation/#Geocoding_Examples
GeoKit::Geocoders::google = 'ABQIAAAA9SJU_KM1xFyYF25w-fqt3RSK6lNkiEITkMWRgqZRn-3t8TtvgRTlFntCmvGpacrZqeLCnvUTq6XWVA'
    
# This is your username and password for geocoder.us.
# To use the free service, the value can be set to nil or false.  For 
# usage tied to an account, the value should be set to username:password.
# See http://geocoder.us
# and http://geocoder.us/user/signup
GeoKit::Geocoders::geocoder_us = false 

# This is your authorization key for geocoder.ca.
# To use the free service, the value can be set to nil or false.  For 
# usage tied to an account, set the value to the key obtained from
# Geocoder.ca.
# See http://geocoder.ca
# and http://geocoder.ca/?register=1
GeoKit::Geocoders::geocoder_ca = false

# This is the order in which the geocoders are called in a failover scenario
# If you only want to use a single geocoder, put a single symbol in the array.
# Valid symbols are :google, :yahoo, :us, and :ca.
# Be aware that there are Terms of Use restrictions on how you can use the 
# various geocoders.  Make sure you read up on relevant Terms of Use for each
# geocoder you are going to use.
GeoKit::Geocoders::provider_order = [:google,:yahoo]

 
