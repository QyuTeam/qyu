# frozen_string_literal: true

(
  Dir["#{File.dirname(__FILE__)}/models/*.rb"] + Dir["#{File.dirname(__FILE__)}/models/enums/*.rb"]
).each do |path|
  require path
end
