module Roguelike
	module EventCapable
		def listen_for(event, sender = nil, &block)
			event = event.to_sym
			raise ArgumentError, "You must give a block when setting up an event listener" unless block_given?
			
			Event.listen(event, self, "event_#{event}", sender)

			# don't try to send this to self.class! That'll effect everyone!
			eigenclass = class << self; self; end
			eigenclass.send(:define_method, "event_#{event}".to_sym) do |t|
				block.call(self, t)
			end

			self
		end

		def ignore(event, sender = nil)
			Event.ignore(event, self, sender)

			self
		end
	end
end
