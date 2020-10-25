require 'matrix'
require 'pry'

RSpec.describe Bender do
  let(:lines) do
    _lines = File.open(File.join(File.dirname(__FILE__), 'fixtures', file_name)).readlines[1..-1]
    _lines.map { |line| line.chomp.chars }
  end

  let(:city_map) { Bender::CityMap.new(lines) }

  context 'Simple Moves' do
    let(:file_name) { 'simple_moves.txt' }
    let(:expected_route) { %w[SOUTH SOUTH EAST EAST] }

    it "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end

  context 'Obstacles' do
    let(:file_name) { 'obstacles.txt' }
    let(:expected_route) { %w[SOUTH EAST EAST EAST SOUTH EAST SOUTH SOUTH SOUTH] }

    it "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end

  context 'Priorities' do
    let(:file_name) { 'priorities.txt' }
    let(:expected_route) { %w[SOUTH SOUTH EAST EAST EAST NORTH NORTH NORTH NORTH NORTH] }

    it "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end

  context 'Straight Line' do
    let(:file_name) { 'straight_line.txt' }
    let(:expected_route) { %w[EAST EAST EAST EAST SOUTH SOUTH SOUTH SOUTH] }

    it "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end

  context 'Path Modifier' do
    let(:file_name) { 'path_modifier.txt' }
    let(:expected_route) { %w[SOUTH SOUTH EAST EAST EAST EAST EAST EAST NORTH NORTH NORTH NORTH NORTH NORTH WEST WEST WEST WEST SOUTH SOUTH] }

    it "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end

  context 'Inverter' do
    let(:file_name) { 'inverter.txt' }
    let(:expected_route) { %w[SOUTH SOUTH SOUTH SOUTH WEST WEST WEST WEST WEST WEST WEST NORTH NORTH NORTH NORTH NORTH NORTH NORTH EAST EAST EAST EAST EAST EAST EAST SOUTH SOUTH] }

    it "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end

  context 'Breaker' do
    let(:file_name) { 'breaker.txt' }
    let(:expected_route) { %w[SOUTH SOUTH SOUTH SOUTH EAST EAST EAST EAST EAST EAST] }

    it "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end

  context 'Teleporter' do
    let(:file_name) { 'teleporter.txt' }
    let(:expected_route) { %w[SOUTH SOUTH SOUTH EAST EAST EAST EAST EAST EAST EAST SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH] }

    it "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end

  context 'Broken wall' do
    let(:file_name) { 'broken_wall.txt' }
    let(:expected_route) { %w[SOUTH SOUTH SOUTH SOUTH EAST EAST EAST EAST NORTH NORTH WEST WEST WEST WEST SOUTH SOUTH SOUTH SOUTH EAST EAST EAST EAST EAST] }


    it "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end

  context 'All together' do
    let(:file_name) { 'all_together.txt' }
    let(:expected_route) { %w[SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH WEST WEST NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH EAST EAST EAST EAST EAST EAST EAST EAST EAST EAST EAST EAST SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH WEST WEST WEST WEST WEST WEST SOUTH SOUTH SOUTH EAST EAST EAST ] }

    it "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end

  context 'Loop' do
    let(:file_name) { 'loop.txt' }
    let(:expected_route) { %w[LOOP] }

    it "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end

  context 'Multiple Loops' do
    let(:file_name) { 'loop.txt' }
    let(:expected_route) { %w[ SOUTH SOUTH SOUTH SOUTH EAST EAST EAST EAST NORTH NORTH NORTH NORTH WEST WEST SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH EAST EAST EAST NORTH WEST WEST WEST WEST WEST SOUTH SOUTH EAST EAST EAST EAST NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH WEST WEST SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH EAST EAST EAST NORTH WEST WEST WEST WEST WEST SOUTH SOUTH EAST EAST EAST EAST NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH NORTH WEST WEST SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH EAST EAST EAST SOUTH SOUTH SOUTH WEST WEST WEST WEST WEST SOUTH SOUTH EAST EAST EAST EAST NORTH NORTH NORTH NORTH WEST WEST SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH SOUTH EAST EAST EAST EAST] }

    xit "follows the correct route" do
      expect(Bender::Journey.new(city_map).call).to eq expected_route
    end
  end
end
