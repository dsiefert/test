module Roguelike
	class Event
		# TODO: Give event origins an x/y location so that the player can witness them, or not.
		#
		# TODO: **IMPORTANT** Figure out a way to register multiple event handler methods on an
		# object that listens for the same event on multiple types.

		@@log       = []
		@@summary   = []
		@@listeners = []

		attr_reader :event_name, :sender, :time, :offset

		def self.listen(name, listener, callback = nil, sender = nil)
			# first remove any existing listeners by the same object for the same event on the same sender
			ignore(name, listener, sender)
			@@listeners << EventListener.new(name, listener, (callback || name.to_sym), sender)
		end

		def self.ignore(name, listener, sender = nil)
			@@listeners.reject! do |l|
				l.name == name &&
				l.listener == listener &&
				(sender.nil? || l.sender.nil? || l.sender == sender || l.sender === sender || sender === l.sender)
			end
		end

		def self.forget_object(listener)
			@@listeners.reject! { |l| l.listener == listener }
		end

		def self.summary
			@@summary
		end

		def heard?
			@heard
		end

		def unheard?
			!@heard
		end

		def hear
			@heard = true
		end

		def initialize(event_name, sender, options = {})
			@event_name = event_name.to_sym
			@sender = sender
			@time = Time.now
			@offset = @@log.last ? Time.now - @@log.last.time : 0.0
			@unheard = true

			@@log.push(self)
			@@summary.push("#{event_name}, by #{sender.class} (#{sender.object_id}) at #{@time} (#{@offset})")

			listeners = @@listeners.dup
			if !options.empty?
				if (coords = options.delete(:local))
					listeners.select!{ |l| Game.dungeon_level.movables(coords).include?(l.listener) }
				end

				if (target = options.delete(:target))
					listeners.select!{ |l| l.listener == target }
				end
			end

			listeners.map { |l| l.alert(sender, self) if l.name == event_name }
		end
	end

	class EventListener
		attr_reader :name, :listener, :sender

		def initialize(name, listener, callback, sender)
			@name     = name
			@listener = listener
			@callback = callback
			@sender   = sender
		end

		def alert(sender, event)
			if @listener.map == Game.dungeon_level && (@sender.nil? || @sender === sender)
				@listener.send(@callback, sender)
				event.hear
			end
		end
	end
end
