module Roguelike
	class Monster < Point
		# TODO: method to capture whether or not the thing has been seen before, which will
		# among other things indicate whether to use 'the' or 'a' in reference to it
		
		include EventCapable
		
		attr_reader :name
		attr_accessor :color

		def initialize(map, x, y, name, character, color) #will later add type or something
			super(map, x, y)

			@name, @character, @color = name, character, color

			map.add_movable(self)
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

			if @map.walkable?(@x + x, @y + y)
				@x += x
				@y += y
			end
		end
	end
end
