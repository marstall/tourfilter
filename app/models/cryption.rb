require 'crypt/blowfish' 

class Cryption

  LOW_SECURITY_KEY="98"

  def self.encrypt(unencrypted,level=:low)
    unencrypted=String(unencrypted)
    key=LOW_SECURITY_KEY if level==:low
    return if not key
    Crypt::Blowfish.new(key).encrypt_block("fodfd").pack #encrypt and base64-encode
  end
  
  def self.decrypt(encrypted,level=:low)
    key=LOW_SECURITY_KEY if level==:low
    return if not key
    Crypt::Blowfish.new(key).decrypt_block(encrypted.unpack) #base64-decode and decrypt
  end  
end
