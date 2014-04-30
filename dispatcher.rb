module Roguelike
	module Dispatcher
		module_function

		@message_queue = []
		@message_log = []

		class << self
			attr_reader :message_queue, :message_log
		end

		def queue_message(message)
			message_queue.push(message)

			true
		end

		def clear_messages
			# message area is rows 25-29
			(25 .. 29).each do |y|
				$window.move(y, 0)
				$window.clrtoeol
			end
		end

		def display_messages
			clear_messages

			row = 25
			while row < 29 && (message = message_queue.shift) do
				$window.attrset(Ncurses::COLOR_PAIR(8))
				$window.mvaddstr(row, 0, message)
				row += 1
			end

			# if !message_queue.empty?
			# TODO: pause and allow for message reset; set the keyboard dispatcher into some sort of :message mode
		end

		def handle(char)
			if char == 27
				$window.nodelay(true)
				char = $window.getch

				if char == -1
					Game.over
				else
					message_queue.push("Pressed 27+#{char}")
				end

				$window.nodelay(false)
			else
				# normal key pressed
				case char
				when 49
					Game.player.move(-1, 1)
				when 50
					Game.player.move(0, 1)
				when 51
					Game.player.move(1, 1)
				when 52
					Game.player.move(-1, 0)
				when 53
					Game.player.move(0, 0)
				when 54
					Game.player.move(1, 0)
				when 55
					Game.player.move(-1, -1)
				when 56
					Game.player.move(0, -1)
				when 57
					Game.player.move(1, -1)
				else
					message_queue.push("Pressed #{char}")
				end
			end
			Game.dungeon_level.draw
		end
	end
end
