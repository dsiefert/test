module Roguelike
	module Event
		module Capable
			def listen_for(event, sender = nil, &block)
				event = event.to_sym
				raise ArgumentError, "You must give a block when setting up an event listener" unless block_given?

				Event.listen(event, self, "event_#{event}", sender)

				# don't try to send this to self.class! That'll effect everyone!
				singleton_class = class << self; self; end
				singleton_class.send(:define_method, "event_#{event}".to_sym) do |t|
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
end
