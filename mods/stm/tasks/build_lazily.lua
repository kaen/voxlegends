local FIND_PATH = 1
local TRAVEL = 2
local GET_TASK = 3
local WORK = 4
return {
  plan = function(char, state)
    state.state = FIND_PATH
  end,
  perform = function(char, state)
    if BuildOrder.get(state.order):is_complete() then return true end

    if state.state == FIND_PATH then

      if not state.adjacent_positions then
        state.adjacent_positions = BuildOrder.get(state.order):find_adjacent_positions()
        state.surface_positions = nil
        state.adjacent_position_index = 1
      end

      -- we've tried all adjacent positions (or there are none)
      local xz_coords = state.adjacent_positions[state.adjacent_position_index]
      if not xz_coords then return false end

      if not state.surface_positions then
        state.surface_positions = MapData.get_all_surface_pos(xz_coords)
        state.surface_position_index = 1
      elseif not state.surface_positions[state.surface_position_index] then
        -- we've tried all surface sites at this position, move to the
        -- next adjacent position
        state.adjacent_position_index = state.adjacent_position_index + 1
        return
      end

      char:push_task('move', { dest = state.surface_positions[state.surface_position_index] })
      state.state = TRAVEL

    elseif state.state == TRAVEL then
      if char.last_task_result then
        state.state = GET_TASK
      else
        state.state = FIND_PATH
        state.surface_position_index = state.surface_position_index + 1
      end

    elseif state.state == GET_TASK then
      state.job = BuildOrder.get(state.order):take_job(char.pos)
      if not state.job then return end
      -- for now, workers can build infinitely up or down
      state.state = WORK

    elseif state.state == WORK then
      table.insert(stm.data.set_node_queue, { pos = state.job.pos, node = state.job.node })
      BuildOrder.get(state.order):complete_job(state.job.id)
      state.state = GET_TASK
    end
  end
}