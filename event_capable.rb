module Roguelike
	module EventCapable
		def method_missing(method, *args)
			# check if it starts with event_ or set_, handle appropriately
		end

		def respond_to?(method)
			# check if it starts with event_ or set_
		end
	end
end
