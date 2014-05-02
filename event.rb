module Roguelike
	class Event
		@@log       = []
		@@summary   = []
		@@listeners = []

		attr_reader :event_name, :target, :time, :offset

		def self.listen(name, listener, callback, target = nil, &block)
			@@listeners << EventListener.new(name, listener, callback, target, &block)
		end

		def self.summary
			@@summary
		end

		def initialize(event_name, target)
			@event_name = event_name
			@target = target
			@time = Time.now
			@offset = @@log.last ? Time.now - @@log.last.time : 0.0

			@@log.push(self)
			@@summary.push("#{event_name}, by #{target.class} (#{target.object_id}) at #{@time} (#{@offset})")


			@@listeners.map { |l| l.alert(target) if l.name == event_name }
		end
	end

	class EventListener
		attr_reader :name

		def initialize(name, listener, callback, target, &block)
			@name     = name
			@listener = listener
			@callback = callback
			@target   = target
			@block    = block if block_given?
		end

		def alert(target)
			@listener.send(@callback, target) if (!@block || @block.call) && (@target.nil? || @target == target)
		end
	end
end
