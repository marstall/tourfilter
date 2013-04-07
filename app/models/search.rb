class Search
  
def self.initialize(params)
    @query=params[:query]
end

  attr_reader :query
  attr_writer :query
end