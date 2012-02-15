class CompareTicketsController < ApplicationController
  def compare_tickets
    @full_width_footer=true
    @match=Match.find(params[:id])
    @ticket_offers = @match.ticket_offers
  end
end