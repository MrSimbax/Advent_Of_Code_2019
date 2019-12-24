using OffsetArrays

function load_data(filename)
    open(filename, "r") do file
        data = permutedims(hcat(collect.(String.(split(read(file, String), '\n', keepempty = false)))...))
        map(c->if c == '#' 1 else 0 end, data)
    end
end

function center2D(grid::AbstractArray{T,3}, level = 0) where {T}
    return CartesianIndex(ceil(Int, size(grid, 1) / 2), ceil(Int, size(grid, 2) / 2), level)
end

function in_bounds(grid::AbstractArray{T,N}, pos::CartesianIndex{N}) where {T,N}
    all(i->pos[i] ∈ axes(grid, i), 1:N)
end

function get_neighbours(grid::AbstractArray{T,3}, pos::CartesianIndex{3}) where {T}
    # Deal with it case by case like with teleporters
    neighbors = Vector{CartesianIndex{3}}()
    up = CartesianIndex(pos[1] - 1, pos[2], pos[3])
    down = CartesianIndex(pos[1] + 1, pos[2], pos[3])
    right = CartesianIndex(pos[1], pos[2] + 1, pos[3])
    left = CartesianIndex(pos[1], pos[2] - 1, pos[3])
    center = center2D(grid, pos[3])

    # Level down
    if up[1] < first(axes(grid,1)) # Top edge
        up = CartesianIndex(center[1] - 1, center[2], pos[3] - 1)
    end
    if down[1] > last(axes(grid,1)) # Bottom edge
        down = CartesianIndex(center[1] + 1, center[2], pos[3] - 1)
    end
    if left[2] < first(axes(grid,2)) # Left edge
        left = CartesianIndex(center[1], center[2] - 1, pos[3] - 1)
    end
    if right[2] > last(axes(grid,2)) # right edge
        right = CartesianIndex(center[1], center[2] + 1, pos[3] - 1)
    end

    neighbors = Vector{CartesianIndex}()

    # Level up
    if up == center
        append!(neighbors, [down, left, right])
        append!(neighbors, [CartesianIndex(size(grid,1), x, pos[3] + 1) for x ∈ 1:size(grid,2)])
    elseif down == center
        append!(neighbors, [up, left, right])
        append!(neighbors, [CartesianIndex(1, x, pos[3] + 1) for x ∈ 1:size(grid,2)])
    elseif left == center
        append!(neighbors, [up, down, right])
        append!(neighbors, [CartesianIndex(y, size(grid,2), pos[3] + 1) for y ∈ 1:size(grid,1)])
    elseif right == center
        append!(neighbors, [up, down, left])
        append!(neighbors, [CartesianIndex(y, 1, pos[3] + 1) for y ∈ 1:size(grid,1)])
    else
        append!(neighbors, [up, down, left, right])
    end

    # println("pos=",pos)
    # println("neighbors=", neighbors)

    filter!(n->in_bounds(grid, n), neighbors)

    return neighbors
end

function count_neighbors(grid::AbstractArray{Int,3})
    N = similar(grid)
    for i ∈ CartesianIndices(grid)
        if i == center2D(grid, i[3])
            N[i] = -1
        end
        N[i] = count(p->grid[p] == 1, get_neighbours(grid, i))
    end
    return N
end

function update_grid!(grid::AbstractArray{Int,3})
    N = count_neighbors(grid)
    for i ∈ CartesianIndices(grid)
        if i == center2D(grid, i[3])
            grid[i] = -1
        elseif grid[i] == 1 && N[i] != 1
            grid[i] = 0
        elseif grid[i] == 0 && (N[i] == 1 || N[i] == 2)
            grid[i] = 1
        end
    end
    return grid
end

function draw(grid::AbstractArray{T,N}) where {T,N}
    display(grid); println()
end

function part2(init_grid::AbstractArray{Int,3}, T::Int)
    grid = copy(init_grid)
    for t ∈ 1:T
        # println("t=",t)
        update_grid!(grid)
        # draw(grid)
        # readline()
    end
    # draw(grid)
    count(p->p==1, grid)
end

function main()
    T = 200
    maxlvl = ceil(Int, T / 2)
    data = load_data("input24.txt")
    draw(data)
    grid = fill(0, size(data)..., 2 * maxlvl + 1)
    grid = OffsetArray(grid, (axes(grid,1), axes(grid,2), (-maxlvl):maxlvl))
    grid[:,:,0] .= data
    println("PART 2: ", part2(grid, T))
end

main()
