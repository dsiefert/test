# TODO: Third type of movable, maybe? The Immovable? For things like doors, staircases etc.
# Define the class along with subclasses so that we can just be all like
# Roguelike::Items::Staircase.new(destination)

module Roguelike
	module Items
		class Item < ::Roguelike::Point
			include ::Roguelike::Event::Capable

			attr_reader   :name
			attr_accessor :color

			def initialize(x, y, name, character, color, params = {}) #will later add type or something
				super(x, y)

				@name, @character, @color = name, character, color

				listen_for(:tread, Game.player) { Dispatcher.queue_message("You step on a #{name}!") }

				listen_for(:hug, Game.player) do |me|
					Dispatcher.queue_message("You hug the #{name}. What kind of freak are you?")
				end

				@walkable = true
				params.each_pair do |k, v|
					instance_variable_set("@#{k}", v)
				end

				self
			end

			def walkable?
				@walkable
			end

			def remove
				Event::Event.forget_object(self)
				Game.level.remove_movable(self)
			end
		end
	end
end
