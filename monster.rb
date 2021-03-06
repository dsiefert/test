module Roguelike
	class Monster < Point
		# TODO: implement different movement modes: :random, :chase, :flee

		# TODO: method to capture whether or not the thing has been seen before, which will
		# among other things indicate whether to use 'the' or 'a' in reference to it
		# 	maybe by means of a 'see' event the player passes the monster whenever the monster
		# 	is drawn (i.e. when it's visible?)

		# TODO: methods to get different versions of the name, at least with:
		# varying plurality and definiteness
		# 	the Canadian, a Canadian, some Canadians, the Canadians

		include ::Roguelike::Event::Capable

		attr_reader :name
		attr_accessor :color

		def initialize(x, y, name, character, color) #will later add type or something
			super(x, y)

			@name, @character, @color = name, character, color

			listen_for(:hug, Game.player) do |me|
				Dispatcher.queue_message("You hug the #{name}. What kind of freak are you?")
			end
		end

		def walkable?
			false
		end

		def move(x = nil, y = nil)
			# TODO: monsters and players both need a way to select a random walkable direction
			# if one exists

			if x.nil?
				x = [-1, 0, 1].sample
				y = [-1, 0, 1].sample
				return move if (x == 0 && y == 0)
			end
			x, y = x if y.nil?

			if Game.level.walkable?(@x + x, @y + y)
				@x += x
				@y += y

				Event::Event.new(:tread, self, local: [@x, @y])
			end
		end
	end
end
