# TODO: Third type of movable, maybe? The Immovable? For things like doors, staircases etc.
# Define the class along with subclasses so that we can just be all like
# Roguelike::Items::Staircase.new(destination)

module Roguelike
	module Items
		class Item < ::Roguelike::Point
			include ::Roguelike::Event::Capable

			attr_reader   :name, :takeable, :fancy_name
			attr_accessor :color

			def initialize(x, y, name, character, color, params = {}) #will later add type or something
				super(x, y)

				@name, @character, @color = name, character, color
				@takeable                 = !!params[:takeable]
				@fancy_name               = params[:fancy_name] || name.capitalize

				listen_for(:tread, Game.player) { Dispatcher.queue_message("You step on a #{name}!") }

				listen_for(:hug, Game.player) do |me|
					Dispatcher.queue_message("You hug the #{name}. What kind of freak are you?")
				end

				listen_for(:take, Game.player) do |me|
					if @takeable
						Dispatcher.queue_message("You take the #{name}.")
						Game.player.inventory.add(me)
						Game.level.remove_movable(self)
					else
						Dispatcher.queue_message("You can't possibly take the #{name}!")
					end
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
