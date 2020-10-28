require 'matrix'
require 'pry'

RSpec.describe Bender do

  let(:lines) do
    _lines = File.open(File.join(File.dirname(__FILE__), 'fixtures', file_name)).readlines[1..-1]
    _lines.map { |line| line.chomp.chars }
  end

  let(:city_map) { Bender::CityMap.new(lines) }

  context 'Multiple Loops' do
    let(:file_name) { 'multiple_loops.txt' }
    let(:expected_route) do
      %w[
          SOUTH SOUTH SOUTH SOUTH EAST EAST EAST EAST NORTH NORTH

          NORTH NORTH WEST WEST SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH

          SOUTH SOUTH EAST EAST EAST NORTH WEST WEST WEST WEST

          WEST SOUTH SOUTH EAST EAST EAST EAST NORTH NORTH NORTH

          NORTH NORTH NORTH NORTH NORTH NORTH WEST WEST SOUTH SOUTH

          SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH

          SOUTH EAST EAST EAST NORTH WEST WEST WEST WEST WEST

          SOUTH SOUTH EAST EAST EAST EAST NORTH NORTH NORTH NORTH

          NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH

          WEST WEST SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH

          SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH

          EAST EAST EAST SOUTH SOUTH SOUTH WEST WEST WEST WEST

          WEST SOUTH SOUTH EAST EAST EAST EAST NORTH NORTH NORTH

          NORTH WEST WEST SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH

          SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH

          SOUTH SOUTH EAST EAST EAST EAST
      ]
    end

    class Debugger
      def initialize(city_map, expected_route)
        @city_map    = city_map
        @expected_route = expected_route
      end

      def call
        prior_cell = city_map.start

        expected_route.each_with_index.map do |direction, index|
          next_cell = next_move_in(direction.downcase, prior_cell)

          if next_cell.teleporter?
            next_cell = city_map.next_teleporter(prior_cell)
          end

          puts " #{index + 1} #{direction} #{next_cell.position} #{next_cell.value}"
          prior_cell = next_cell
        end
      end

      def next_move_in(direction, prior_cell)
        city_map.send(direction, prior_cell)
      end

      private

      attr_reader :city_map, :expected_route
    end

    it "follows the correct route" do
      results = Debugger.new(city_map, expected_route).call
      expect(results.count).to eq 156
      binding.pry
    end

  end
end
