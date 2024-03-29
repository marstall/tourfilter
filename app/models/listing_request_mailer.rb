class ListingRequestMailer < ActionMailer::Base

  def listing_request(info)
    @subject    = "New Listing Request"
    @body       = info
    @recipients = "listings@psychoastronomy.org"
    @from       = 'info@tourfilter.com'
    @sent_on    = DateTime.now
    @headers    = {}
  end
end
