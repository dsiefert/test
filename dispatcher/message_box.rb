module Roguelike
  module Dispatcher
    class Line
      attr_reader :text

      def initialize(type, text)
        @type = type
        @text = text
      end

      def length
        @text.length
      end

      def draw(row, col)
        $window.mvaddstr(row, col, text)
      end
    end

    class Box
      MAX_COLS = 60
      MAX_ROWS = 15

      def initialize
        @row_offset = 0
      end

      def break_text(type, text)
    		# create lines of text -- up to dialog_width characters per line
    		@lines = []
    		paragraphs = text.split("\n").map(&:strip)
    		paragraphs.each do |paragraph|
    			words = paragraph.split(" ").map(&:strip)
    			line = ""
    			while !words.empty?
    				word = words.shift
    				if line.length + word.length + 1 <= MAX_COLS then
    					line = line + " " + word
    					line.strip!
    				else
    					@lines.push(Line.new(type, line))
    					line = word
    				end
    			end
    			@lines.push(Line.new(text, line))
    			line = ""
    		end
      end

      def draw_lines
    		$window.attron(Ncurses::COLOR_PAIR(10))
    		@lines[@row_offset ... @row_offset + MAX_ROWS].each_with_index do |line, offset|
    			$window.mvaddstr((12 - (height / 2)) + offset, (80 - width) / 2, " " * width)
    			col = @center ? 39 - l.length / 2 : (80 - width) / 2
    			line.draw((12 - (height / 2)) + offset, col)
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
    			$window.attron(Ncurses::COLOR_PAIR(12))
    			$window.mvaddstr(row, left_edge, " ")
          $window.mvaddstr(row, left_edge + width + 3, " ")
          $window.attron(Ncurses::COLOR_PAIR(10))
          $window.mvaddstr(row, left_edge + 1, " ")
          $window.mvaddstr(row, left_edge + width + 2, " ")
    		end
        $window.attron(Ncurses::COLOR_PAIR(12))
    		$window.mvaddstr(rows.first, left_edge, " " * (width + 4))
    		$window.mvaddstr(rows.last, left_edge, " " * (width + 4))

    		$window.attron(Ncurses::COLOR_PAIR(10))
    		$window.mvaddstr(rows.first + 1, left_edge + 1, " " * (width + 2))
    		$window.mvaddstr(rows.last - 1, left_edge + 1, " " * (width + 2))
    		$window.attroff(Ncurses::COLOR_PAIR(10))
      end
    end

    class MessageBox < Box
    	def initialize(text, options = {})
        super()

        @center = !!options[:center]

        break_text(:text, text)

        # process dialog options
        # add length of @options (in lines) to some instance variable, stop using @lines.length to represent the entire length of the dialog
        # each option must need to know the position of its top and bottom line
        # probably no protection against super long text plus options, there's no reason to do that anyway

        draw_frame

    		Roguelike::Dispatcher.clear_messages

    		draw_lines
        draw_scroll_bar
        # highlight_option

    		@display = true
    		while @display
    			case $window.getch
    			when 27
    				$window.nodelay(true)
    				char = $window.getch
    				if char == -1
    					@display = false
    				elsif char == 91
    					char_2 = $window.getch
              # handle up and down arrows
              # if @options is empty, just scroll a line at a time
              # if it isn't, check to see if scrolling is needed to get the next option on the screen
    					if char_2 == 65
    						@row_offset -= 1
    						@row_offset = 0 if @row_offset < 0
    						draw_lines
    						draw_scroll_bar
    					elsif char_2 == 66
    						@row_offset += 1
    						@row_offset -= 1 if @row_offset > length - MAX_ROWS
    						draw_lines
    						draw_scroll_bar
    					end
    				end
    				$window.nodelay(false)
    			when 10, 13
    				@display = false
    			end
    		end

    		$window.attron(Ncurses::COLOR_PAIR(8))
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
        		$window.attron(Ncurses::COLOR_PAIR(11))
        	elsif r >= upper_space + size
        		$window.attron(Ncurses::COLOR_PAIR(10))
        	end
          $window.mvaddstr(row, column, " ")
        end

        $window.move(25, 0)
      end
    end
  end
end
