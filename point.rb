module Roguelike
	class Point
		attr_reader :x, :y, :map

		def initialize(map, x, y)
			@x = x
			@y = y

			raise Error, "Map not specified" if !map.is_a?(Roguelike::DungeonLevel)

			@map = map
		end

		def location
			[x, y]
		end

		def draw
			if @color.nil? || @character.nil? || @x.nil? || @y.nil?
				raise Error, "Required attribute not set. Cannot draw point: #{@x}, #{@y} (Character: #{@character}, color: #{@color})"
			end

			if !@x.is_a?(Fixnum) || @x < 0 || @x >= @map.columns
				raise Error, "Specified x value out of bounds. Cannot draw point: #{@x}, #{@y}"
			end

			if !@y.is_a?(Fixnum) || @y < 0 || @y >= @map.rows
				raise Error, "Specified y value out of bounds. Cannot draw point: #{@x}, #{@y}"
			end

			color = @color
			if color > 8
				color -= 8
				$window.attron(Ncurses::A_BOLD)
			end

			$window.attron(Ncurses::COLOR_PAIR(color))
			$window.mvaddstr(@y + @map.offset_y, @x + @map.offset_x, @character[0])
			$window.attroff(Ncurses::A_BOLD)
		end
	end
end
