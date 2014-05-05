module Roguelike
	module EventCapable
		def listen_for(event, target = nil, &block)
			event = event.to_sym
			raise ArgumentError, "You must give a block when setting up an event listener" unless block_given?
			
			instance_variable_set("@#{event}", block)

			Event.listen(event, self, "event_#{event}", target)

			# don't try to send this to self.class! That'll effect everyone!
			eigenclass = class << self; self; end
			eigenclass.send(:define_method, "event_#{event}".to_sym) do |t|
				block.call(t, self)
			end
		end
	end
end
