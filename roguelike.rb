#!/home/damon/.rbenv/shims/ruby

# TODO, for fun:
# Work out some concept of establishing 'clear' (walkable) directions for player & monsters
# Set monster walk mode: :wander, :chase, :flee
# Induce our purple wandering Canadian to chase the player under some circumstance
# Introduce monsters emitting actions
# See if we can get the angry floor tile to eat him

require 'ncursesw'
require_relative 'game'

module Roguelike
	class Error < ::StandardError
	end

	farewell_messages = [
		"Live long and prosper.",
		"May the force be with you.",
		"May the wind be ever at your back.",
		"May the road rise to meet your feet.",
		"Fare thee well.",
		"Play more roguelike games!",
		"Send me a check!"
	]

	begin
		# check that window is at least 80x25

		$window = Ncurses.initscr
		Ncurses.start_color
		Ncurses.use_default_colors
		Ncurses.noecho
		Ncurses.cbreak

		Ncurses.init_pair(1, 0, 0)
		Ncurses.init_pair(2, 1, 0)
		Ncurses.init_pair(3, 2, 0)
		Ncurses.init_pair(4, 3, 0)
		Ncurses.init_pair(5, 4, 0)
		Ncurses.init_pair(6, 5, 0)
		Ncurses.init_pair(7, 6, 0)
		Ncurses.init_pair(8, 7, 0)

		$window.bkgd(Ncurses.COLOR_PAIR(8));

		Game.start

		until Game.over?
			Game.take_turn
		end

		Dispatcher.display_messages

		# loop:
		# allow all characters to take turns
		# if PC is still alive, continue

		# dywypi

	ensure
		Ncurses.nocbreak
		Ncurses.endwin
	end

	# Event.summary.each { |e| puts e }
	# puts dungeon_level.map_attempts
	# puts dungeon_level.room_area
	puts Game.end_message if Game.end_message
	puts farewell_messages.sample
end
