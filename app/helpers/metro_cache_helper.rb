module MetroCacheHelper
  def metro_cache(hash, &block)
    hash[:action]="#{@metro_code}_#{hash[:action]}"
    hash[:skip_relative_url_root]=true
    metro_cache_erb_fragment(block, hash)
  end

end
