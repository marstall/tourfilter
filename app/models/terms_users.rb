class TermsUsers < ActiveRecord::Base
  set_table_name "terms_users"
  has_one :term,
          :foreign_key => "id"
  has_one :user
end
