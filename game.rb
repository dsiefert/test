require_relative 'event/event'
require_relative 'point'
require_relative 'items/items'
require_relative 'place'
require_relative 'dispatcher'
require_relative 'player'

module Roguelike
	class Game
		attr_reader :player
		attr_accessor :level

		def self.method_missing(method, *args, &block)
			if self.instance.respond_to?(method)
				self.instance.send(method, *args, &block)
			else
				super
			end
		end

		def self.to_yaml
			self.instance.to_yaml
		end

		def self.respond_to?(method)
			self.instance.respond_to?(method) || super
		end

		def self.instance
			@instance ||= Game.new
		end

		def start
			Game.player = Player.new
			level = Place.new.initial_level
			level.depth = 1
			Game.level = level
			Game.player.set_location(level.unmarked_rooms.sample.mark.random_square)
			level.draw
			Event::Event.new(:enter, Game.player)
		end

		def take_turn
			Event::Event.new(:turn, self)
			Game.level.draw
			Dispatcher.handle($window.getch)
		end

		def over?
			@over
		end

		def over!(message = nil)
			@over = true

			level.draw(false)

			message ||= "Game over. Waah waah waah."
			Dispatcher.queue_message(message, true)
		end

		def player=(player)
			@player = player unless @player
		end

		def end_message
			@end_message
		end
	end
end
