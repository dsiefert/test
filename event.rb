module Roguelike
	class Event
		@@log = []
		@@summary = []

		attr_reader :event_name, :target, :time, :offset

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
		end
	end
end
