# == Schema Information
#
# Table name: access_tokens
#
#  id           :bigint           not null, primary key
#  last_used_at :datetime
#  owner_type   :string
#  scopes       :string           default([]), not null, is an Array
#  token        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  owner_id     :bigint
#
# Indexes
#
#  index_access_tokens_on_owner_type_and_owner_id  (owner_type,owner_id)
#  index_access_tokens_on_token                    (token) UNIQUE
#

class AccessToken < ApplicationRecord
  has_secure_token :token
  belongs_to :owner, polymorphic: true
end
