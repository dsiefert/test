module Roguelike
	module Event
		class Listener
			attr_reader :name, :listener, :sender

			def initialize(name, listener, callback, sender)
				@name     = name
				@listener = listener
				@callback = callback
				@sender   = sender
			end

			def alert(sender, event)
				if @listener.map == Game.level && (@sender.nil? || @sender === sender)
					@listener.send(@callback, sender)
					event.hear
				end
			end
		end
	end
end
