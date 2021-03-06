local TRAVEL = 1
local WORK = 2
local GET_TASK = 3
return {
  plan = function(char, state)
    state.state = GET_TASK
  end,
  perform = function(char, state)
    if state.state == GET_TASK then
      if BuildOrder.get(state.order):is_complete() then return true end

      state.task = BuildOrder.get(state.order):take_job(char.pos)
      if not state.task then return end

      state.surface_sites = nil
      state.site_index = nil
      state.state = TRAVEL

    elseif state.state == TRAVEL then
      -- if the job is already done, move to the next one
      if MapData.get_node(state.task.pos).name == state.task.name then
        state.state = GET_TASK
        BuildOrder.get(state.order):complete_job(state.task.id)
        return
      end

      -- try pathing to any surface position at this x,z point
      if not state.surface_sites then
        state.surface_sites = { }
        for i=-1,1 do
          for j=-1,1 do
            if i ~= 0 or j ~= 0 then
              local tmp = vector.new(state.task.pos.x + i, state.task.pos.y, state.task.pos.z + j)
              for k,v in pairs(MapData.get_all_surface_pos(tmp)) do
                table.insert(state.surface_sites, v)
              end
            end
          end
        end
        state.site_index = 1
      elseif state.site_index > #state.surface_sites then
        -- we've tried all surface sites and could not get to any of them
        state.state = GET_TASK
        return
      end

      -- for now, workers can build infinitely up or down
      char:push_task('move', { dest = state.surface_sites[state.site_index], distance = 2 })
      state.state = WORK

    elseif state.state == WORK then
      -- if the move was successful, do work
      if char.last_task_result then
        table.insert(stm.data.set_node_queue, {pos = state.task.pos, node = { name = state.task.name }})
        state.state = GET_TASK
      else
        -- if we couldn't path there, try the next surface site
        state.state = TRAVEL
        state.site_index = state.site_index + 1
      end
    end
  end
}