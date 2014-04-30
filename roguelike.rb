#!/home/damon/.rbenv/shims/ruby
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

	titles = [
		"A dark and gloomy snide field",
		"A mysterious dungeon",
		"Some caves or something",
		"A dark place",
		"A maze of twisty little passages, all alike",
		"Wait, what?",
		"Somewhere deep below the ground",
		"The lair of some foul creature",
		"An abandoned dwarven settlement",
		"Somewhere that smells bad",
		"A vast network of claustrophobic tunnels"
	]

	# generate new PC

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

		dungeon_level = Roguelike::DungeonLevel.new(titles.sample)
		Game.dungeon_level = dungeon_level
		Game.player = Player.new(dungeon_level, 39, 12)
		dungeon_level.draw

		# loop:
		# allow all characters to take turns
		# if PC is still alive, continue

		until Game.over? do
			Dispatcher.handle($window.getch)
		end

		# dywypi

	ensure
		Ncurses.nocbreak
		Ncurses.endwin
	end

	# Event.summary.each { |e| puts e }
	# puts dungeon_level.map_attempts
	# puts dungeon_level.room_area
	puts farewell_messages.sample
end
