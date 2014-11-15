require_relative 'message_box'

module Roguelike
	module Dispatcher
		module_function

		@message_queue = []
		@message_log = []

		class << self
			attr_reader :message_queue, :message_log
		end

		def wait
			until [10,13,27,32].include?($window.getch) do; end
		end

		def queue_message(text, force_acknowledgment = false)
			message_queue << Message.new(text, force_acknowledgment)

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
			paused = false

			row = 25
			while row < 29 && (message = message_queue.shift) do
				message_log << message

				$window.attrset(Ncurses::COLOR_PAIR(8))
				$window.mvaddstr(row, 0, message.text)

				if message.force_acknowledgment || Game.over?
					$window.addstr(" (paused)")
					paused = true
					wait
				end

				row += 1
			end

			clear_messages if paused

			# if !message_queue.empty?
			# TODO: pause and allow for message reset; set the keyboard dispatcher into some sort of :message mode
		end

		def select_direction
			queue_message("Select a direction.")
			display_messages

			while char = $window.getch
				direction = case char.chr
				when "1"
					[-1, 1]
				when "2"
					[0, 1]
				when "3"
					[1, 1]
				when "4"
					[-1, 0]
				when "5"
					[0, 0]
				when "6"
					[1, 0]
				when "7"
					[-1, -1]
				when "8"
					[0, -1]
				when "9"
					[1, -1]
				when 27.chr
					false
				else
					nil
				end
				break unless direction.nil?
			end

			direction
		end

		def select_square
			queue_message("Select a location.")
			display_messages

			coord_x = Game.player.x + Game.level.offset_x
			coord_y = Game.player.y + Game.level.offset_y

			$window.move(coord_y, coord_x)

			x_min = Game.level.offset_x
			y_min = Game.level.offset_y
			x_max = Game.level.columns - 1 + Game.level.offset_x
			y_max = Game.level.rows - 1 + Game.level.offset_y

			done = false
			while char = $window.getch
				case char.chr
				when "1"
					coord_x -= 1
					coord_y += 1
				when "2"
					coord_y += 1
				when "3"
					coord_x += 1
					coord_y += 1
				when "4"
					coord_x -= 1
				when "6"
					coord_x += 1
				when "7"
					coord_x -= 1
					coord_y -= 1
				when "8"
					coord_y -= 1
				when "9"
					coord_x += 1
					coord_y -= 1
				when 10.chr, 13.chr, 32.chr
					done = true
				when 27.chr
					done = true
					coord_x, coord_y = [0, 0] # force it to choose a random character
				end

				coord_x = [x_min, coord_x].max
				coord_x = [x_max, coord_x].min
				coord_y = [y_min, coord_y].max
				coord_y = [y_max, coord_y].min

				$window.move(coord_y, coord_x)

				break if done
			end

			coord_x -= Game.level.offset_x
			coord_y -= Game.level.offset_y

			[coord_x, coord_y]
		end

		def handle(char)
			if char == 27
				$window.nodelay(true)
				char = $window.getch

				if char == -1
					Game.over!
				end

				if char == 91
					char_2 = $window.getch
					case char_2
					when 65
						Game.player.move(0, -1)
					when 66
						Game.player.move(0, 1)
					when 67
						Game.player.move(1, 0)
					when 68
						Game.player.move(-1, 0)
					else
						queue_message("Then pressed #{char_2}")
					end
				end

				$window.nodelay(false)
			else
				# normal key pressed
				case char.chr
				when "1"
					Game.player.move(-1, 1)
				when "2"
					Game.player.move(0, 1)
				when "3"
					Game.player.move(1, 1)
				when "4"
					Game.player.move(-1, 0)
				when "5"
					Game.player.move(0, 0)
				when "6"
					Game.player.move(1, 0)
				when "7"
					Game.player.move(-1, -1)
				when "8"
					Game.player.move(0, -1)
				when "9"
					Game.player.move(1, -1)
				when 't'
					Game.player.teleport
				when 'T'
					Game.player.controlled_teleport
				when 's'
					Game.player.sneeze
				when 'r'
					Game.level.reveal
				when 'h'
					Game.player.hug(select_direction)
				when '>'
					Game.player.descend
				when '<'
					Game.player.ascend
				when '@'
					MessageBox.new("you pick up the ancient manuscript and begin to puzzle out the old-fashioned script\n\nthere will be few survivors\nand our only god shall be oprah\nand our fear of her shall be matched only by our adoration of her\nwe shall despair in her absence and cower in her presence and all that she decrees shall be done\n\na smattering of popsicles\n\nthe churlish screams of a thousand churlish bees filled the air on a warm summer evening in the coldest place in the solar system\n\nlove,\nthe prince\n\n\nAnd the enormous ship of fools\nSailed forth across the waters\nAnd we never learned the truth\nOf what had happened to our daughters\n\nThe sun-parched desert bloomed\nAnd we never thought to ask\nWhat had been consumed\nBy our appointed task\n\n\nThe book was inscribed with strange symbols, and none of us could read it, but when we finally spoke about it, we discovered we had all had the same dreams afterwards.\n\nThere were caves, and a distant sound of whispering, and a tall, beautiful woman with a smile as cold and as alluring as a Sno-Cone.\n\nWe never spoke again and soon retreated off into our own private despairs. I learned that I'm the last to survive -- John hung himself, Ronald shot himself, Philip drank himself to death, and I never really believed that Arthur drank that antifreeze by accident.\n\nBut here I am, and I don't know why I still live, and I don't know if my family and my friends and my happiness are an undeserved mercy that was never extended to my friends, or just to keep me alive until the right time, for some purpose yet unknown to me.\n\n\nThe princess spoke sweetly and her touch was gentle as she bent down over me.\n\n\"Yes, this one will do nicely,\" she said. \"How long can you keep him alive once the process begins? I wish to watch as long as possible.\"\n\n\"He will remain alive for several hours, Your Highness, and his suffering will be exquisite,\" the doctor told her. \"I promise you'll enjoy his screams.\"")
        when '#'
          options = [
            Option.new("Numbers:"),
            Option.new("one", 1),
            Option.new("two", 2),
            Option.new("three", 3)
          ]
          OptionsBox.new("Choose a number!", options)
        else
					queue_message("Pressed #{char}")
				end
			end
		end

		class Message
			attr_reader :text, :force_acknowledgment

			def initialize(text, force_acknowledgment)
				@text                 = text
				@force_acknowledgment = force_acknowledgment
			end
		end
	end
end
