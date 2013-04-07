require "rubygems"
require "net/http"
require "aws"

class S3

  @initialized=false

  @default_bucket="tourfilter.com"

  def self.init
    if not @initialized
      @s3 = AWS::S3.new
#      Base.establish_connection!(
#        :access_key_id     => $AMAZON_CREDS['access_key_id'],
#        :secret_access_key => $AMAZON_CREDS['secret_access_key'],
#        :use_ssl=>true
#      )  
      @initialized=true
    end
  end
  
  def self.move_to_s3(filename,bucket=nil,access=:public_read)
    init
    url = copy_to_s3(filename,bucket||@default_bucket)
    File.delete(filename)
    return url
  end

  def self.copy_to_s3(filename,bucket=nil,access=:public_read)
    init
    name = File.basename(filename)
    @s3.buckets[bucket||@default_bucket].objects[name].write(:file=>filename,:acl => :public_read)
#    AWS::S3::S3Object.store(name, open(filename), bucket||@default_bucket, {:access => access})
    return "http://s3.amazonaws.com/tourfilter.com/#{name}"
  end

  def self.delete(filename,bucket=nil)
    name = File.basename(filename)
    @s3.buckets[bucket||@default_bucket].objects[name].delete
#    AWS::S3::S3Object.delete(name,bucket||@default_bucket)
  end

  def self.test
    require "../../config/environment.rb"
    puts "testing s3 file write/read/delete ..."
    puts "creating file ..."
    filename = "tmp3.txt"
    file = File.new(filename,"w")
    data = "test data"
    file.write(data)
    file.close
    puts "uploading file to s3, default bucket ..."
    move_to_s3("tmp3.txt")
    puts "SUCCESS."
    url = "https://s3.amazonaws.com/tourfilter.com/#{filename}"
    puts "accessing uploaded file via web @ #{url} ..."
    read_data = open(url).read
    success=true
    if read_data==data
      puts "SUCCESS. Read data (#{read_data}) same as written data (#{data})."
    else
      success=false
      puts "FAILURE. Read data(#{read_data}) different from written data (#{data})."
    end
    puts "deleting uploaded file..."
    delete(filename)
    puts "verifying that the file is no longer accessible on the web ..."
    read_data_2 = open(url).read rescue
    if read_data_2==data
      success=false
      puts "FAILURE. File could still be read (#{read_data_2} same as #{data})"
    else
      puts "SUCCESS. File is deleted."
    end
    if success
      puts "Test passed."
    else
      puts "Test failed."
    end
  end

end

#S3.test

