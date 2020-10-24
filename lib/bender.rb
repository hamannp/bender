require 'bender/version'
require 'matrix'
require 'forwardable'
require 'set'

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

    def start?
      CityMap::START == value
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

    def blankify(position)
      street_map[*position] = ' '
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
              :cell_value, :start?] => :cell

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

    def decorators
      options[:decorators]
    end

    def method_missing(m, *args, &block)
      overridable_method = "_#{m}"

      # TODO: Prefer Teleporter over other decorators to make jump
      if m == :next_state && Array(decorators).include?(TeleporterDecorator)
        return _next_state
      end

      decorator_class ||= Array(decorators).detect do |decorator_class|
        decorator_class.instance_methods.include?(m)
      end

      if decorator_class
        return decorator_class.new(self).send(m, *args)
      end

      if respond_to?(overridable_method)
        send(overridable_method, *args)
      end
    end

    def _transition_allowed_to?(next_cell)
      [
        CityMap::OPEN_SPACE,
        CityMap::FINISH,
        CityMap::INVERTED,
        CityMap::BREAKER,
        CityMap::TELEPORTER
      ].include?(next_cell.value) || cardinal_direction?(next_cell.value)
    end

    def _move_order
      options[:move_order] || DEFAULT_MOVE_ORDER
    end

    def _next_state
      if prior_state && prior_state.direction
        candidate_state = make_next_adjacent_move(prior_state.direction)
        return candidate_state if candidate_state
      end

      make_next_allowed_move
    end

    def make_next_adjacent_move(candidate_direction)
      next_cell = next_move_in(candidate_direction.downcase)

      # TODO: could be problematic for loop
      return if journey.states.map(&:cell_position).include?(next_cell.position)

      if transition_allowed_to?(next_cell)
        self.direction = candidate_direction
        make_next_state(next_cell, candidate_direction)
      end
    end

    def make_next_allowed_move
      move_order.each do |candidate_direction|
        candidate_state = make_next_adjacent_move(candidate_direction)
        return candidate_state if candidate_state
      end
    end

    def _next_move_in(direction)
      city_map.send(direction, prior_state.cell)
    end

    def make_next_state(next_cell, direction)
      next_state           = self.class.new(journey, self)
      next_state.cell      = next_cell
      next_state.direction = direction
      next_state
    end
  end

  class Decorator
    extend Forwardable
    delegate [ :prior_state, :journey, :city_map ] => :state

    def initialize(state)
      @state = state
    end

    def options
      state.options
    end

    private

    attr_reader :state
  end

  class ModifiedDecorator < Decorator
    def next_state
      if state.transition_allowed_to?(next_cell)
        state.make_next_state(next_cell, options[:modified_direction].upcase)
      else
        state.make_next_allowed_move
      end
    end

    private

    def next_cell
      @next_cell ||= next_move_in(options[:modified_direction])
    end

    def next_move_in(direction)
      state.city_map.send(direction, state.prior_state.cell)
    end
  end

  class BreakerDecorator < Decorator
    def transition_allowed_to?(next_cell)
      cell_value = next_cell.value

      result = state._transition_allowed_to?(next_cell) ||
        CityMap::BREAKABLES.include?(cell_value)

        if blankify_mode?(cell_value)
          city_map.blankify(next_cell.position)
        end

      result
    end

    private

    def blankify_mode?(cell_value)
      CityMap::BREAKABLES.include?(cell_value) &&
        journey.breakables_encountered_count == 1
    end
  end

  class TeleporterDecorator < Decorator
    def next_move_in(candidate_direction)
      city_map.next_teleporter(starting_teleporter)
    end

    private

    def starting_teleporter
      prior_state.cell_position
    end
  end

  class InverterDecorator < Decorator
    def move_order
      JourneyState::INVERTED_MOVE_ORDER
    end
  end

  class JourneyStateStart < JourneyState
    def initialize(journey, prior_state, options={})
      super

      @cell = city_map.start
    end
  end

  class Journey
    attr_reader :city_map
    attr_accessor :states, :decorators

    def initialize(city_map)
      @city_map   = city_map
      @states     = []
      @decorators = Set.new
    end

    def call
      next_state  = JourneyStateStart.new(self, nil)
      options     = {}

      until next_state.finished? do
        next_value = next_state.cell_value

        toggle(TeleporterDecorator) if decorators.include?(TeleporterDecorator)

        if next_state.cardinal_direction?(next_value)
          decorators << ModifiedDecorator
          options[:modified_direction] = city_map.modified_direction_for(next_value)

        elsif next_state.inverted?
          toggle(InverterDecorator)

        elsif next_state.breakable?
          toggle(BreakerDecorator)

        elsif next_state.teleporter?
          perform_half_of_teleport_loop
        end

        options[:decorators] = decorators
        next_state           = JourneyState.new(self, next_state, options).next_state

        self.states << next_state
      end

      states.map(&:direction)
    end

    def breakables_encountered_count
      states.select(&:breakable?).count
    end

    private

    def toggle(decorator)
      if decorators.include?(decorator)
        decorators.reject! { |d| d == decorator }
      else
        decorators << decorator
      end
    end

    def perform_half_of_teleport_loop
      completing_teleport_jump? ? states.pop : self.decorators.add(TeleporterDecorator)
    end

    def completing_teleport_jump?
      states.count > 1 && states[-1].teleporter? && states[-2].teleporter?
    end

  end

end
