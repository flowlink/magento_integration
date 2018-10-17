# frozen_string_literal: true

module HashTools
  module_function

  def convert_keys_to_symbols(hash)
    hash.each_with_object({}) { |(key, value), memo| memo[key.to_sym] = value; }
  end
end
