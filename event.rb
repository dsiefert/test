module Roguelike
	class Event
		@@log       = []
		@@summary   = []
		@@listeners = []

		attr_reader :event_name, :target, :time, :offset

		def self.listen(name, listener)
			@@listeners << [name, listener]
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

			listeners = @@listeners.select { |l| l.first == event_name }.map { |l| l.last }
			listeners.each { |l| l.send(event_name, target) }
		end
	end
end
