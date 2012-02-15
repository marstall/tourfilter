module ActionMailer

  class Base

    # enable partials in ActionMailer templates, there is still a lot to be
    # done to make it work with auto multi-part partials
    def self.controller_path #:nodoc:
      return  ''
    end
  end
end