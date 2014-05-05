module Roguelike
	class Event
		# TODO: Clean these up so they only work on the currently-loaded map. No triggering events
		# on maps that aren't displayed.
		#
		# TODO: Give event origins an x/y location so that the player can witness them, or not.
		#
		# TODO: Handle local events a bit more cleanly, with an options hash {:local => [x, y]}
		# Other options may yield themselves with time.
		#
		# TODO: **IMPORTANT** Figure out a way to register multiple event handler methods on an
		# object that listens for the same event on multiple types.

		@@log       = []
		@@summary   = []
		@@listeners = []

		attr_reader :event_name, :sender, :time, :offset

		def self.listen(name, listener, callback = nil, sender = nil, &block)
			# first remove any existing listeners by the same object for the same event on the same sender
			ignore(name, listener, sender)

			@@listeners << EventListener.new(name, listener, callback || name.to_sym, sender, &block)
		end

		def self.ignore(name, listener, sender = nil)
			@@listeners.reject! do |l|
				l.name == name &&
				l.listener == listener &&
				(sender.nil? || l.sender.nil? || l.sender == sender)
			end
		end

		def self.forget_object(listener)
			@@listeners.reject! { |l| l.listener == listener }
		end

		def self.summary
			@@summary
		end

		def initialize(event_name, sender, options = {})
			@event_name = event_name.to_sym
			@sender = sender
			@time = Time.now
			@offset = @@log.last ? Time.now - @@log.last.time : 0.0

			@@log.push(self)
			@@summary.push("#{event_name}, by #{sender.class} (#{sender.object_id}) at #{@time} (#{@offset})")

			listeners = @@listeners.dup
			if !options.empty?
				if (coords = options.delete(:local))
					listeners.select!{ |l| Game.dungeon_level.movables(coords).include?(l.listener) }
				end
			end

			listeners.map { |l| l.alert(sender) if l.name == event_name }
		end
	end

	class EventListener
		attr_reader :name, :listener, :sender

		def initialize(name, listener, callback, sender, &block)
			@name     = name
			@listener = listener
			@callback = callback
			@sender   = sender
			@block    = block if block_given?
		end

		def alert(sender)
			@listener.send(@callback, sender) if (!@block || @block.call) && (@sender.nil? || @sender === sender)
		end
	end
end
