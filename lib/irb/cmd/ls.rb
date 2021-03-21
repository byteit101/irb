# frozen_string_literal: true

require "reline"
require_relative "nop"
require_relative "../color"

# :stopdoc:
module IRB
  module ExtendCommand
    class Ls < Nop
      def execute(*arg, grep: nil)
        o = Output.new(grep: grep)

        obj    = arg.empty? ? irb_context.workspace.main : arg.first
        locals = arg.empty? ? irb_context.workspace.binding.local_variables : []
        klass  = (obj.class == Class || obj.class == Module ? obj : obj.class)

        o.dump("constants", obj.constants) if obj.respond_to?(:constants)
        o.dump("#{klass}.methods", obj.singleton_methods(false))
        o.dump("#{klass}#methods", klass.public_instance_methods(false))
        o.dump("instance variables", obj.instance_variables)
        o.dump("class variables", klass.class_variables)
        o.dump("locals", locals)
      end

      class Output
        MARGIN = "  "

        def initialize(grep: nil)
          @grep = grep
          @line_width = screen_width
        end

        def dump(name, strs)
          strs = strs.grep(@grep) if @grep
          strs = strs.sort
          return if strs.empty?

          # Attempt a single line
          print "#{Color.colorize(name, [:BOLD, :BLUE])}: "
          if fits_on_line?(strs, cols: strs.size, offset: "#{name}: ".length)
            puts strs.join(MARGIN)
            return
          end
          puts

          # Dump with the largest # of columns that fits on a line
          cols = strs.size
          until fits_on_line?(strs, cols: cols, offset: MARGIN.length) || cols == 1
            cols -= 1
          end
          widths = col_widths(strs, cols: cols)
          strs.each_slice(cols) do |ss|
            puts ss.map.with_index { |s, i| "#{MARGIN}%-#{widths[i]}s" % s }.join
          end
        end

        private

        def fits_on_line?(strs, cols:, offset: 0)
          width = col_widths(strs, cols: cols).sum + MARGIN.length * (cols - 1)
          width <= @line_width - offset
        end

        def col_widths(strs, cols:)
          cols.times.map do |col|
            (col...strs.size).step(cols).map do |i|
              strs[i].length
            end.max
          end
        end

        def screen_width
          Reline.get_screen_size.last
        rescue Errno::EINVAL # in `winsize': Invalid argument - <STDIN>
          79
        end
      end
      private_constant :Output
    end
  end
end
# :startdoc:
