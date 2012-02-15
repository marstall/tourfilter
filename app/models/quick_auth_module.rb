module QuickAuthModule
  SALT="E801014980G"
  def quick_auth_token(user)
    return nil if user.nil?
    Digest::MD5.hexdigest("#{user.id}_#{user.password[0..2]}_#{SALT}")
  end
  
  def quick_authenticate(params)
    id=params[:id]
    auth_token=params[:auth_token]
    user = User.find(id) rescue nil
    logger.info "at: #{auth_token}"
    logger.info "qat: #{quick_auth_token(user)}"
    auth_token==quick_auth_token(user)
  end
end