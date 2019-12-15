include("IntCode.jl")
using .IntCode

using OffsetArrays
using Plots

pyplot()

"""
Self-growing 2D grid with center at (0,0).

It will grow twice in size each time a position out of bounds is reached
in order to minimize the amount of allocations.

New parts of the grid will be initialized to -1 to indicate "undefined".
Such a tile can be treated as being in fog of war/unvisited/etc.

Note: since Julia keeps standard arrays in column-major order,
    indexes are (y, x) not (x, y).
"""
mutable struct Grid
    # Raw data
    raw_grid::Array{Int,2}

    # For easy access
    grid::OffsetArray{Int,2}

    # Bounds
    min_x::Int
    max_x::Int
    min_y::Int
    max_y::Int
end

function Grid(min_x::Int, max_x::Int, min_y::Int, max_y::Int)
    raw_grid = fill(-1, max_y - min_y + 1, max_x - min_x + 1)
    grid = OffsetArray(raw_grid, min_y:max_y, min_x:max_x)
    Grid(raw_grid, grid, min_x, max_x, min_y, max_y)
end

function Grid()
    Grid(0, 0, 0, 0)
end

function Grid(grid::Grid, init = -1)
    raw_grid = fill(init, grid.max_y - grid.min_y + 1, grid.max_x - grid.min_x + 1)
    offset_grid = OffsetArray(raw_grid, grid.min_y:grid.max_y, grid.min_x:grid.max_x)
    Grid(raw_grid, offset_grid, grid.min_x, grid.max_x, grid.min_y, grid.max_y)
end

function update_offset_array!(grid::Grid)
    grid.grid = OffsetArray(grid.raw_grid, grid.min_y:grid.max_y, grid.min_x:grid.max_x)
end

function expand_grid!(grid::Grid, pos::Vector{Int})
    # WARNING: assuming the new pos will not exceed two times the current length
    ly = grid.max_y - grid.min_y + 1
    lx = grid.max_x - grid.min_x + 1
    if pos[1] < grid.min_y
        grid.min_y -= ly
        grid.raw_grid = vcat(fill(-1, ly, lx), grid.raw_grid)
        update_offset_array!(grid)
    end
    if pos[1] > grid.max_y
        grid.max_y += ly
        grid.raw_grid = vcat(grid.raw_grid, fill(-1, ly, lx))
        update_offset_array!(grid)
    end
    if pos[2] < grid.min_x
        grid.min_x -= lx
        grid.raw_grid = hcat(fill(-1, ly, lx), grid.raw_grid)
        update_offset_array!(grid)
    end
    if pos[2] > grid.max_x
        grid.max_x += lx
        grid.raw_grid = hcat(grid.raw_grid, fill(-1, ly, lx))
        update_offset_array!(grid)
    end
end

# Grid access functions
function set_tile!(grid::Grid, pos::Vector{Int}, x::Int)
    expand_grid!(grid, pos)
    grid.grid[pos...] = x
end

function get_tile!(grid::Grid, pos::Vector{Int})
    expand_grid!(grid, pos)
    return grid.grid[pos...]
end

function in_bounds(grid::Grid, pos::Vector{Int})
    return grid.min_y <= pos[1] <= grid.max_y &&
           grid.min_x <= pos[2] <= grid.max_x
end

function get_neighbours(pos::Vector{Int})
    [
        [ pos[1] + 1, pos[2]     ],
        [ pos[1],     pos[2] + 1 ],
        [ pos[1] - 1, pos[2]     ],
        [ pos[1],     pos[2] - 1 ]
    ]
end

function get_neighbours_in_bounds(grid::Grid, pos::Vector{Int})
    filter!(p->in_bounds(grid, p), get_neighbours(pos))
end

function trace_back_path(distance_grid::Grid, from::Vector{Int}, to::Vector{Int})
    path = Vector{Vector{Int}}()
    while from != to
        push!(path, to)
        N = filter!(n->get_tile!(distance_grid, n) >= 0, get_neighbours_in_bounds(distance_grid, to))
        i = argmin(map(n->get_tile!(distance_grid, n), N))
        to = N[i]
    end
    return path
end

"""
Will return an array of points or nothing if path was not found.

Provide the numbers indicating which tiles are walkable. Any other tile
will be considered an obstacle.
"""
function find_path(grid::Grid, from::Vector{Int}, to::Vector{Int};
    walkable = Set([1,2]))

    # Make a copy of the grid which will keep distances
    # We'll run BFS and then backtrack using the copy
    # Note: this should probably be rewritten to use A*

    distance_grid = Grid(grid)
    set_tile!(distance_grid, from, 0)
    Q = [from]
    while !isempty(Q)
        v = pop!(Q)
        if v == to
            # Found it!
            return trace_back_path(distance_grid, from, to)
        end
        dist_v = get_tile!(distance_grid, v)
        for n ∈ get_neighbours_in_bounds(distance_grid, v)
            if get_tile!(distance_grid, n) < 0 && (get_tile!(grid, n) ∈ walkable || n == to)
                set_tile!(distance_grid, n, dist_v + 1)
                pushfirst!(Q, n)
            end
        end
    end
    return nothing
end

function draw(grid::Grid, robot_pos::Vector{Int} = [0,0])
    # io = IOBuffer()
    # for y ∈ grid.max_y:-1:grid.min_y
    #     for x ∈ grid.min_x:grid.max_x
    #         c = get_tile!(grid, [y,x])
    #         if [y,x] == robot_pos
    #             print(io, '●')
    #         elseif c == -1 # unknown
    #             print(io, '▫')
    #         elseif c == 0 # wall
    #             print(io, '■')
    #         elseif c == 1 # walkable tile
    #             print(io, ' ')
    #         elseif c == 2 # oxygen system
    #             print(io, '◎')
    #         else
    #             error("Bad tile at ($x, $y): $c")
    #         end
    #     end
    #     println(io)
    # end
    # println(String(take!(io)))
    height = grid.max_y - grid.min_y + 1
    width = grid.max_x - grid.min_x + 1
    data = fill(RGB(0, 0, 0), height, width)
    offset_data = OffsetArray(data, grid.min_y:grid.max_y, grid.min_x:grid.max_x)
    for y ∈ grid.max_y:-1:grid.min_y
        for x ∈ grid.min_x:grid.max_x
            c = get_tile!(grid, [y,x])
            if [y,x] == robot_pos
                offset_data[y,x] = RGB(0, 0, 1)
            elseif c == -1 # unknown
                continue
            elseif c == 0 # wall
                offset_data[y,x] = RGB(1, 1, 1)
            elseif c == 1 # walkable tile
                offset_data[y,x] = RGB(0.5, 0.5, 0.5)
            elseif c == 2 # oxygen system
                offset_data[y,x] = RGB(0, 1, 0)
            else
                error("Bad tile at ($x, $y): $c")
            end
        end
    end
    # size = max(width, height)
    # scale = size > 10 ? (size > 30 ? 8 : 16) : 32
    width = 60
    height = 60
    scale = 12
    plot(data, yflip = false, axis = nothing,
        size = (width * scale, height * scale),
        background_color_outside = RGB(0, 0, 0))
end

function render(grid::Grid, robot_pos::Vector{Int}, anim = nothing)
    # run(`cmd /c cls`)
    plt = draw(grid, robot_pos)
    if anim === nothing
        display(plt)
        sleep(1 / 60)
    else
        frame(anim)
    end
end

function get_movement_instruction(robot_pos::Vector{Int}, goal::Vector{Int})
    if robot_pos[2] < goal[2]
        # east
        4
    elseif goal[2] < robot_pos[2]
        # west
        3
    elseif goal[1] < robot_pos[1]
        # south
        2
    else # robot_pos[1] < goal[1]
        # north
        1
    end
end

function move_robot!(program::Program, robot_pos::Vector{Int}, next::Vector{Int})
    push!(program.in, get_movement_instruction(robot_pos, next))
    run_program!(program)
    pop!(program.out)
end

function check_for_walls!(grid::Grid, program::Program, robot_pos::Vector{Int},
    unvisited_tiles::Vector{Vector{Int}})
    
    walls = Vector{Vector{Int}}()
    for n ∈ get_neighbours(robot_pos)
        if get_tile!(grid, n) < 0
            push!(walls, n)
        end
    end
    while !isempty(walls)
        next = pop!(walls)
        status = move_robot!(program, robot_pos, next)
        if status == 0
            # Mark as wall
            set_tile!(grid, next, status)
        else
            # We'll visit it later
            push!(unvisited_tiles, next)

            # Come back to initial position
            move_robot!(program, next, robot_pos)
        end
    end
end

function next_unvisited(grid::Grid, unvisited_tiles::Vector{Vector{Int}})
    while !isempty(unvisited_tiles)
        unvisited = pop!(unvisited_tiles)
        if get_tile!(grid, unvisited) >= 0
            continue
        else
            return unvisited
        end
    end
    return nothing
end

function main(anim = nothing)
    srccode = read_src("input15.txt")
    
    # Part 1
    # DFS to find the whole map
    robot_pos = [0, 0]
    goal_pos = [0, 0]
    grid = Grid()
    set_tile!(grid, robot_pos, 0)
    unvisited_tiles = Vector{Vector{Int}}()
    
    # Set up
    in = Array{Int,1}()
    out = Array{Int,1}()
    program = Program(copy(srccode), in, out)

    while !program.halted
        check_for_walls!(grid, program, robot_pos, unvisited_tiles)
        render(grid, robot_pos, anim)

        # Now visit any remaining unvisited tiles
        unvisited = next_unvisited(grid, unvisited_tiles)
        if unvisited === nothing
            break
        end

        path = find_path(grid, robot_pos, unvisited)
        if path === nothing || isempty(path)
            error("Can't find path from $robot_pos to $unvisited")
        end

        # Instruct the robot through the path of already visited nodes
        status = -1
        while length(path) > 1
            next = pop!(path)
            status = move_robot!(program, robot_pos, next)
            robot_pos = next
            render(grid, robot_pos, anim)
        end
            
        # Now the final goal (guaranteed to be unvisited)
        next = pop!(path)
        status = move_robot!(program, robot_pos, next)
        set_tile!(grid, next, status)
        if status != 0
            robot_pos = next
            if status == 2
                goal_pos = next
            end
        end
    end

    path = find_path(grid, [0,0], goal_pos)
    println("PART 1: ", length(path))
    
    # Visualization: go to goal
    path = find_path(grid, robot_pos, goal_pos)
    while !isempty(path)
        next = pop!(path)
        move_robot!(program, robot_pos, next)
        robot_pos = next
        render(grid, robot_pos, anim)
    end

    # Part 2
    # BFS
    start = goal_pos
    Q = [start]
    time_grid = Grid(grid)
    set_tile!(time_grid, start, 0)
    prevt = 0
    while !isempty(Q)
        v = pop!(Q)
        t = get_tile!(time_grid, v)
        if prevt != t
            prevt = t
            render(grid, robot_pos, anim)
        end
        for n ∈ get_neighbours_in_bounds(grid, v)
            tile = get_tile!(grid, n)
            if tile > 0 && tile != 2
                set_tile!(grid, n, 2)
                set_tile!(time_grid, n, t + 1)
                pushfirst!(Q, n)
            end
        end
    end

    println("PART 2: ", maximum(time_grid.raw_grid))

    # println(grid.min_x, ":", grid.max_x)
    # println(grid.min_y, ":", grid.max_y)
end

anim = Animation()
main(anim)
mp4(anim, "./day15.mp4")
