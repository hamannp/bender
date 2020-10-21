require 'bender/version'
require 'matrix'
require 'forwardable'

module Bender
  class Cell < Struct.new(:position, :value)

    alias cell_position position
    alias cell_value value

    def north
      [position[0] - 1, position[1]]
    end

    def south
      [position[0] + 1, position[1]]
    end

    def east
      [position[0], position[1] + 1]
    end

    def west
      [position[0], position[1] - 1]
    end

    def finished?
      CityMap::FINISH == value
    end

    def inverted?
      CityMap::INVERTED == value
    end

    def breakable?
      CityMap::BREAKER == value
    end

    def teleporter?
      CityMap::TELEPORTER == value
    end
  end

  class CityMap
    START      = '@'.freeze
    FINISH     = '$'.freeze
    OPEN_SPACE = ' '.freeze
    INVERTED   = 'I'.freeze
    BREAKER    = 'B'.freeze
    TELEPORTER = 'T'.freeze

    SOUTH      = 'SOUTH'.freeze
    NORTH      = 'NORTH'.freeze
    EAST       = 'EAST'.freeze
    WEST       = 'WEST'.freeze
    BREAKABLES = %w[X]

    CARDINAL_DIRECTIONS = {
      'E' => EAST,
      'W' => WEST,
      'N' => NORTH,
      'S' => SOUTH
    }.freeze

    def initialize(lines)
      @street_map = Matrix[*lines]
    end

    def start
      @start ||= find(START)
    end

    def finish
      @finish ||= find(FINISH)
    end

    def north(current_cell)
      move(current_cell.north)
    end

    def south(current_cell)
      move(current_cell.south)
    end

    def east(current_cell)
      move(current_cell.east)
    end

    def west(current_cell)
      move(current_cell.west)
    end

    def cardinal_direction?(candidate_value)
      CARDINAL_DIRECTIONS.keys.include?(candidate_value)
    end

    def modified_direction_for(abbreviated_value)
      CARDINAL_DIRECTIONS[abbreviated_value].downcase
    end

    def next_teleporter(current_teleporter)
      new_index = nil

      street_map.to_a.map.each_with_index do |row_value, row_index|
        # TODO: Add test to cover the case of 2 teleporters in the same row.
        index = row_value.find_index do |value|
          value == TELEPORTER
        end

        next if index.nil?
        candidate_teleporter = [row_index, index]

        unless candidate_teleporter == current_teleporter
          new_index = candidate_teleporter
          break
        end
      end

      next_cell(new_index)
    end

    private

    attr_reader :street_map

    def find(value)
      index = street_map.find_index { |v| v == value }
      Cell.new(index, street_map[*index])
    end

    def next_cell(new_index)
      if new_index[1] == -1
        Cell.new(nil, nil)
      else
        Cell.new(new_index, street_map[*new_index])
      end
    end

    alias move next_cell
  end

  class JourneyState
    attr_accessor :direction, :cell
    attr_reader :journey, :prior_state, :options

    extend Forwardable
    def_delegator :journey, :city_map
    def_delegator :city_map, :cardinal_direction?

    delegate [:inverted?, :finished?, :breakable?, :teleporter?, :cell_position,
              :cell_value] => :cell

    DEFAULT_MOVE_ORDER = [
      CityMap::SOUTH,
      CityMap::EAST,
      CityMap::NORTH,
      CityMap::WEST
    ].freeze

    INVERTED_MOVE_ORDER = DEFAULT_MOVE_ORDER.reverse.freeze

    def initialize(journey, prior_state, options={})
      @journey     = journey
      @prior_state = prior_state
      @direction   = nil
      @cell        = nil
      @options     = options
    end

    def follows_teleportation?
      prior_state && prior_state.respond_to?(:prior_state_class)
    end

    def transition_allowed_to?(next_cell)
      [
        CityMap::OPEN_SPACE,
        CityMap::FINISH,
        CityMap::INVERTED,
        CityMap::BREAKER,
        CityMap::TELEPORTER
      ].include?(next_cell.value) || cardinal_direction?(next_cell.value)
    end

    def move_order
      options[:move_order] || DEFAULT_MOVE_ORDER
    end

    def next_state
      if prior_state && prior_state.direction
        _next_state = make_next_adjacent_move(prior_state.direction)
        return _next_state if _next_state

        make_next_allowed_move
      else
        make_next_allowed_move
      end
    end

    private

    def make_next_adjacent_move(candidate_direction)
      next_cell = next_move_in(candidate_direction.downcase)

      if transition_allowed_to?(next_cell)
        self.direction = candidate_direction
        make_next_state(next_cell, candidate_direction)
      end
    end

    def make_next_allowed_move
      move_order.each do |candidate_direction|
        _next_state = make_next_adjacent_move(candidate_direction)
        return _next_state if _next_state
      end
    end

    def next_move_in(direction)
      city_map.send(direction, prior_state.cell)
    end

    def make_next_state(next_cell, direction)
      next_state           = self.class.new(journey, self)
      next_state.cell      = next_cell
      next_state.direction = direction
      next_state
    end
  end

  class JourneyStateModified < JourneyState
    def initialize(journey, prior_state, options={})
      super

      @modified_direction = options[:modified_direction]
    end

    def next_state
      if transition_allowed_to?(next_cell)
        make_next_state(next_cell, modified_direction.upcase)
      end
    end

    def next_cell
      @next_cell ||= next_move_in(modified_direction)
    end

    private

    attr_reader :modified_direction
  end

  class JourneyStateBreaker < JourneyState
    def transition_allowed_to?(next_cell)
      super || CityMap::BREAKABLES.include?(next_cell.value)
    end
  end

  class JourneyStateStart < JourneyState
    def initialize(journey, prior_state, options={})
      super

      @cell = city_map.start
    end
  end

  class JourneyStateTeleporter < JourneyState

    attr_reader :prior_state_class

    def initialize(journey, prior_state, options={})
      super

      @prior_state_class = options[:prior_state_class]
    end

    def next_move_in(_)
      city_map.next_teleporter(starting_teleporter)
    end

    private

    def starting_teleporter
      prior_state.cell_position
    end
  end

  class Journey
    attr_reader :city_map

    def initialize(city_map)
      @city_map = city_map
      @states   = []
    end

    def call
      next_state  = JourneyStateStart.new(self, nil)
      state_class = JourneyState
      options     = {}

      until next_state.finished? do
        next_value = next_state.cell_value

        if next_state.follows_teleportation?
          state_class = next_state.prior_state.prior_state_class
          options[:prior_state_class] = nil

          states.pop
        end

        if next_state.cardinal_direction?(next_value)
          state_class                  = JourneyStateModified
          options[:modified_direction] = city_map.modified_direction_for(next_value)

        elsif next_state.inverted?
          toggle_move_order(options)

        elsif next_state.breakable?
          state_class = toggle_breakable(state_class)

        elsif next_state.teleporter?
          unless next_state.follows_teleportation?
            options[:prior_state_class] = state_class
            state_class = JourneyStateTeleporter
          end
        end

        next_state = state_class.new(self, next_state, options).next_state
        self.states << next_state
      end

      states.map(&:direction)
    end

    private

    attr_accessor :states

    def toggle_breakable(current_state_class)
      if current_state_class == JourneyStateBreaker
        JourneyState
      else
        JourneyStateBreaker
      end
    end

    def toggle_move_order(options)
      if options.key?(:move_order)
        options.delete(:move_order)
      else
        options[:move_order] = JourneyState::INVERTED_MOVE_ORDER
      end
    end
  end

end
