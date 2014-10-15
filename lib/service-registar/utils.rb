#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-10-14 17:31:09 +0100 (Tue, 14 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
module ServiceRegistar
  module Utils
    def postive_integer? value
      return false unless value.is_a? Integer
      return false if value <= 0
      true
    end

    def required_settings list, supplied
      list.each do |x|
        raise ArgumentError, "you have not specified the #{x} options" unless supplied.has_key? x
      end
    end
  end
end