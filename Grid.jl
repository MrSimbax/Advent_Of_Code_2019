module GridModule

export Grid
export set_tile!
export get_tile!
export in_bounds

using OffsetArrays

"""
Self-growing 2D grid with center at (0,0).

It will grow twice in size each time a position out of bounds is reached
in order to minimize the amount of allocations.

New parts of the grid will be initialized to `default`.

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

    # Default tile
    default::Int
end

function Grid(min_x::Int, max_x::Int, min_y::Int, max_y::Int; default = -1)
    raw_grid = fill(default, max_y - min_y + 1, max_x - min_x + 1)
    grid = OffsetArray(raw_grid, min_y:max_y, min_x:max_x)
    Grid(raw_grid, grid, min_x, max_x, min_y, max_y, default)
end

function Grid(; default = -1)
    Grid(0, 0, 0, 0, default = default)
end

function Grid(grid::Grid; default = -1)
    raw_grid = fill(default, grid.max_y - grid.min_y + 1, grid.max_x - grid.min_x + 1)
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
        grid.raw_grid = vcat(fill(grid.default, ly, lx), grid.raw_grid)
        update_offset_array!(grid)
    end
    if pos[1] > grid.max_y
        grid.max_y += ly
        grid.raw_grid = vcat(grid.raw_grid, fill(grid.default, ly, lx))
        update_offset_array!(grid)
    end
    if pos[2] < grid.min_x
        grid.min_x -= lx
        grid.raw_grid = hcat(fill(grid.default, ly, lx), grid.raw_grid)
        update_offset_array!(grid)
    end
    if pos[2] > grid.max_x
        grid.max_x += lx
        grid.raw_grid = hcat(grid.raw_grid, fill(grid.default, ly, lx))
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

end