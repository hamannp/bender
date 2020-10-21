
require 'matrix'
require 'pry'

RSpec.describe Bender::CityMap do
  let(:lines) do
    [
      [' ', Bender::CityMap::START, ' '],
      ['#', 'X', 'S'],
      ['E', ' ', Bender::CityMap::FINISH]
    ]
  end

  let(:city_map) { Bender::CityMap.new(lines) }

  it 'finds the start' do
    expect(city_map.start.position).to eq [0,1]
    expect(city_map.start.value).to eq '@'
  end

  it 'finds the finish' do
    expect(city_map.finish.position).to eq [2, 2]
    expect(city_map.finish.value).to eq '$'
  end

  it 'finds the south move' do
    current_cell = Bender::Cell.new([0,1], '@')
    expect(city_map.south(current_cell)).to eq Bender::Cell.new([1,1], 'X')
  end

  it 'finds the north move' do
    current_cell = Bender::Cell.new([1,1], 'X')
    expect(city_map.north(current_cell)).to eq  Bender::Cell.new([0,1], '@')
  end

  it 'finds the east move' do
    current_cell = Bender::Cell.new([1,1], 'X')
    expect(city_map.east(current_cell)).to eq  Bender::Cell.new([1,2], 'S')
  end

  it 'finds the west move' do
    current_cell = Bender::Cell.new([1,1], 'X')
    expect(city_map.west(current_cell)).to eq  Bender::Cell.new([1,0], '#')
  end

  it 'returns a nil position and blank value when out of range' do
    current_cell = Bender::Cell.new([0,0], ' ')
    expect(city_map.west(current_cell)).to eq  Bender::Cell.new(nil, nil)
  end

end
