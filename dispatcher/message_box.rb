module Roguelike
	module Dispatcher
		class Line
			attr_reader :text

			def initialize(type, text, option = nil)
				@type = type
				@text = text
				@option = option if option && !@text.empty?
			end

			def length
				@text.length
			end

			def draw(row, col)
				$window.mvaddstr(row, col, text)
			end

			def type
				if @option && @option.selected
					:selected
				else
					@type
				end
			end
		end

		class Box
			MAX_COLS = 60
			MAX_ROWS = 15

			def initialize
				@row_offset = 0
			end

			def break_text(text, type = :text, option = nil)
				# create lines of text -- up to dialog_width characters per line
				@lines = [] if !@lines

				rows = Dispatcher::fracture(text, MAX_COLS)
				rows.each{ |row| @lines.push(Line.new(type, row, option)) }

				rows.count
			end

			def draw_lines
				@lines[@row_offset ... @row_offset + MAX_ROWS].each_with_index do |line, offset|
					case line.type
					when :header
						$window.attron(Ncurses::A_BOLD)
						$window.attron(Ncurses::COLOR_PAIR(11))
					when :option
						$window.attron(Ncurses::A_BOLD)
						$window.attron(Ncurses::COLOR_PAIR(10))
					when :selected
						$window.attroff(Ncurses::A_BOLD)
						$window.attron(Ncurses::COLOR_PAIR(14))
					else
						$window.attroff(Ncurses::A_BOLD)
						$window.attron(Ncurses::COLOR_PAIR(10))
					end

					$window.mvaddstr((12 - (height / 2)) + offset, (80 - width) / 2, " " * width)
					col = @center ? 39 - l.length / 2 : (80 - width) / 2
					line.draw((12 - (height / 2)) + offset, col)

					$window.attroff(Ncurses::A_BOLD)
				end

				$window.move(25, 0)
			end

			def length
				@lines.length
			end

			def width
				MAX_COLS
			end

			def height
				[length, MAX_ROWS].min
			end

			def left_edge
				(80 - width) / 2 - 2
			end

			def draw_frame
				# erase area, including two character padding around entire text area
				# draw frame
				top_row = 12 - (height / 2) - 2
				rows = top_row .. top_row + height + 3
				rows.each do |row|
					$window.attron(Ncurses::COLOR_PAIR(13))
					$window.mvaddstr(row, left_edge, " ")
					$window.mvaddstr(row, left_edge + width + 3, " ")
					$window.attron(Ncurses::COLOR_PAIR(10))
					$window.mvaddstr(row, left_edge + 1, " ")
					$window.mvaddstr(row, left_edge + width + 2, " ")
				end
				$window.attron(Ncurses::COLOR_PAIR(13))
				$window.mvaddstr(rows.first, left_edge, " " * (width + 4))
				$window.mvaddstr(rows.last, left_edge, " " * (width + 4))

				$window.attron(Ncurses::COLOR_PAIR(10))
				$window.mvaddstr(rows.first + 1, left_edge + 1, " " * (width + 2))
				$window.mvaddstr(rows.last - 1, left_edge + 1, " " * (width + 2))
				$window.attroff(Ncurses::COLOR_PAIR(10))
			end

			def draw_scroll_bar
				return true if length <= MAX_ROWS

				column = (80 - width) / 2 + MAX_COLS
				column -= 1 if @center
				height = MAX_ROWS + 2
				top_row = 12 - (MAX_ROWS / 2) - 1
				bottom_row = top_row + MAX_ROWS + 1

				ratio = MAX_ROWS.to_f / length
				size = (ratio * height).round

				upper_space = ((@row_offset.to_f / length) * height).round
				upper_space = 1 if upper_space == 0 and @row_offset > 0

				if (length - MAX_ROWS - @row_offset > 0) and (upper_space + size >= height)
					upper_space -= 1
				end

				(0 .. height - 1).each do |r|
					row = r + top_row
					if r < upper_space
						$window.attron(Ncurses::COLOR_PAIR(10))
					elsif r >= upper_space and r < upper_space + size
						$window.attron(Ncurses::COLOR_PAIR(12))
					elsif r >= upper_space + size
						$window.attron(Ncurses::COLOR_PAIR(10))
					end
					$window.mvaddstr(row, column, " ")
				end

				$window.move(25, 0)
			end
		end

		class MessageBox < Box
			def initialize(text, params = {})
				super()

				break_text(text)

				# process dialog options
				# add length of @options (in lines) to some instance variable, stop using @lines.length to represent the entire length of the dialog
				# each option must need to know the position of its top and bottom line
				# probably no protection against super long text plus options, there's no reason to do that anyway

				draw_frame

				Roguelike::Dispatcher.clear_messages

				draw_lines
				draw_scroll_bar

				@display = true
				while @display
					case $window.getch
					when '8'.ord
						@row_offset -= 1
						@row_offset = 0 if @row_offset < 0
					when '2'.ord
						@row_offset += 1
						@row_offset -= 1 if @row_offset > length - MAX_ROWS
					when 27
						$window.nodelay(true)
						char = $window.getch
						if char == -1
							@display = false
						elsif char == 91
							char_2 = $window.getch
							if char_2 == 65
								@row_offset -= 1
								@row_offset = 0 if @row_offset < 0
							elsif char_2 == 66
								@row_offset += 1
								@row_offset -= 1 if @row_offset > length - MAX_ROWS
							end
						end
						$window.nodelay(false)
					when 10, 13
						@display = false
					end
					draw_lines
					draw_scroll_bar
				end

				$window.attron(Ncurses::COLOR_PAIR(8))
			end
		end

		class OptionsBox < Box
			def selectable_options
				@options.reject(&:header)
			end

			def selected_option
				if !selectable_options.select(&:selected).empty?
					selectable_options.select(&:selected).first
				else
					selectable_options.first.select
				end
			end

			def previous_option
				return selectable_options.first unless selected_option

				idx = selectable_options.index(selected_option)
				if idx > 0
					selectable_options[idx - 1]
				else
					selectable_options.first
				end
			end

			def next_option
				return selectable_options.first unless selected_option

				idx = selectable_options.index(selected_option)
				if idx < (selectable_options.length - 1)
					selectable_options[idx + 1]
				else
					selectable_options.last
				end
			end

			def initialize(text, options, params = {})
				super()
				@permit_nil = !!params[:permit_nil]
				@options = []

				break_text(text)

				@lines.push(Line.new(:text, "")) unless options.first.header

				if @permit_nil
					options.push(Option.new("\nCancel", nil))
				end

				options.each do |option|
					option.top = length
					line_count = break_text(option.text, option.header ? :header : :option, option.header ? nil : option)
					option.bottom = option.top + line_count - 1
					option.unselect
					@options.push(option)
				end
				if selectable_options.empty?
					Error.new("No selectable options!")
				end
				selectable_options.first.select
			end

			def select_previous
				@row_offset -= 1 if selected_option == selectable_options.first && @row_offset > 0

				new_option = previous_option
				selected_option.unselect
				new_option.select

				if selected_option.top < @row_offset
					@row_offset = selected_option.top
				end
			end

			def select_next
				new_option = next_option
				selected_option.unselect
				new_option.select

				if selected_option.bottom > (@row_offset + height - 1)
					@row_offset = selected_option.bottom - height + 1
				end
			end

			def display
				draw_frame

				Roguelike::Dispatcher.clear_messages

				draw_lines
				draw_scroll_bar

				@display = true
				while @display
					case $window.getch
					when '8'.ord
						select_previous
					when '2'.ord
						select_next
					when 27
						$window.nodelay(true)
						char = $window.getch
						if char == -1 && @permit_nil
							returnval = nil
							@display = false
						elsif char == 91
							char_2 = $window.getch
							if char_2 == 65
								select_previous
							elsif char_2 == 66
								select_next
							end
						end
						$window.nodelay(false)
					when 10, 13
						returnval = selected_option.returnval
						@display = false
					end
					draw_lines
					draw_scroll_bar
				end

				$window.attron(Ncurses::COLOR_PAIR(8))
				returnval
			end
		end

		class Option
			attr_reader :text, :returnval, :header, :selected
			attr_accessor :top, :bottom

			def select
				@selected = true

				self
			end

			def unselect
				@selected = false

				self
			end

			def initialize(text, returnval = false)
				@text      = text
				@returnval = returnval
				@header    = returnval == false
				@selected  = false
			end
		end
	end
end
