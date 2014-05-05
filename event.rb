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

		attr_reader :event_name, :target, :time, :offset

		def self.listen(name, listener, callback = nil, target = nil, &block)
			# first remove any existing listeners by the same object for the same event on the same target
			ignore(name, listener, target)

			@@listeners << EventListener.new(name, listener, callback || name.to_sym, target, &block)
		end

		def self.ignore(name, listener, target = nil)
			@@listeners.reject! do |l|
				l.name == name &&
				l.listener == listener &&
				(target.nil? || l.target.nil? || l.target == target)
			end
		end

		def self.ignore_all_for_object(listener)
			@@listeners.reject! { |l| l.listener == listener }
		end

		def self.summary
			@@summary
		end

		def initialize(event_name, target, *args)
			@event_name = event_name.to_sym
			@target = target
			@time = Time.now
			@offset = @@log.last ? Time.now - @@log.last.time : 0.0

			@@log.push(self)
			@@summary.push("#{event_name}, by #{target.class} (#{target.object_id}) at #{@time} (#{@offset})")

			listeners = @@listeners.dup
			if !args.empty?
				if args.first == :local
					listeners.select!{ |l| Game.dungeon_level.movables(args[1], args[2]).include?(l.listener) }
				end
			end

			listeners.map { |l| l.alert(target) if l.name == event_name }
		end
	end

	class EventListener
		attr_reader :name, :listener, :target

		def initialize(name, listener, callback, target, &block)
			@name     = name
			@listener = listener
			@callback = callback
			@target   = target
			@block    = block if block_given?
		end

		def alert(target)
			@listener.send(@callback, target) if (!@block || @block.call) && (@target.nil? || @target === target)
		end
	end
end
