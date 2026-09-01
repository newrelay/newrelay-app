require 'administrate/field/base'

class CountField < Administrate::Field::Base
  def to_s
    cached = "#{attribute}_count"
    return resource[cached].to_i if resource.has_attribute?(cached)

    data.count
  end
end
