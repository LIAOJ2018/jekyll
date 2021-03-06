# frozen_string_literal: true

module Jekyll
  class LiquidRenderer
    class Table
      GAUGES = [:count, :bytes, :time].freeze

      def initialize(stats)
        @stats = stats
      end

      def to_s(num_of_rows = 50)
        data = data_for_table(num_of_rows)
        widths = table_widths(data)
        generate_table(data, widths)
      end

      private

      def generate_table(data, widths)
        str = +"\n"

        table_head = data.shift
        table_foot = data.pop

        str << generate_row(table_head, widths)
        str << generate_table_head_border(table_head, widths)

        data.each do |row_data|
          str << generate_row(row_data, widths)
        end

        str << generate_table_head_border(table_foot, widths)
        str << generate_row(table_foot, widths).rstrip

        str << "\n"
        str
      end

      def generate_table_head_border(row_data, widths)
        str = +""

        row_data.each_index do |cell_index|
          str << "-" * widths[cell_index]
          str << "-+-" unless cell_index == row_data.length - 1
        end

        str << "\n"
        str
      end

      def generate_row(row_data, widths)
        str = +""

        row_data.each_with_index do |cell_data, cell_index|
          str << if cell_index.zero?
                   cell_data.ljust(widths[cell_index], " ")
                 else
                   cell_data.rjust(widths[cell_index], " ")
                 end

          str << " | " unless cell_index == row_data.length - 1
        end

        str << "\n"
        str
      end

      def table_widths(data)
        widths = []

        data.each do |row|
          row.each_with_index do |cell, index|
            widths[index] = [cell.length, widths[index]].compact.max
          end
        end

        widths
      end

      # rubocop:disable Metrics/AbcSize
      def data_for_table(num_of_rows)
        sorted = @stats.sort_by { |_, file_stats| -file_stats[:time] }
        sorted = sorted.slice(0, num_of_rows)

        table  = [header_labels]
        totals = Hash.new { |hash, key| hash[key] = 0 }

        sorted.each do |filename, file_stats|
          GAUGES.each { |gauge| totals[gauge] += file_stats[gauge] }
          row = []
          row << filename
          row << file_stats[:count].to_s
          row << format_bytes(file_stats[:bytes])
          row << format("%.3f", file_stats[:time])
          table << row
        end

        footer = []
        footer << "TOTAL (for #{sorted.size} files)"
        footer << totals[:count].to_s
        footer << format_bytes(totals[:bytes])
        footer << format("%.3f", totals[:time])
        table  << footer
      end
      # rubocop:enable Metrics/AbcSize

      def header_labels
        GAUGES.map { |gauge| gauge.to_s.capitalize }.unshift("Filename")
      end

      def format_bytes(bytes)
        bytes /= 1024.0
        format("%.2fK", bytes)
      end
    end
  end
end
