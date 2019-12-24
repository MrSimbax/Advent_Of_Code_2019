function load_data(filename)
    open(filename, "r") do file
        data = permutedims(hcat(collect.(String.(split(read(file, String), '\n', keepempty = false)))...))
        map(c->if c == '#' 1 else 0 end, data)
    end
end

function in_bounds(grid::AbstractArray{T,2}, pos::CartesianIndex{2}) where {T}
    all(i->pos[i] ∈ axes(grid, i), 1:length(pos))
end

function get_neighbours(pos::CartesianIndex{2})
    [
        CartesianIndex(pos[1] + 1, pos[2]),
        CartesianIndex(pos[1], pos[2] + 1),
        CartesianIndex(pos[1] - 1, pos[2]),
        CartesianIndex(pos[1], pos[2] - 1)
    ]
end

function get_neighbours_in_bounds(grid::AbstractArray{T,2}, pos::CartesianIndex{2}) where {T}
    filter!(p->in_bounds(grid, p), get_neighbours(pos))
end

function count_neighbors(grid::AbstractArray{Int,2})
    N = similar(grid)
    for i ∈ CartesianIndices(grid)
        N[i] = count(p->grid[p] == 1, get_neighbours_in_bounds(grid, i))
    end
    return N
end

function update_grid!(grid::AbstractArray{Int,2})
    N = count_neighbors(grid)
    for i ∈ eachindex(grid, N)
        if grid[i] == 1 && N[i] != 1
            grid[i] = 0
        elseif grid[i] == 0 && (N[i] == 1 || N[i] == 2)
            grid[i] = 1
        end
    end
    return grid
end

function rating(grid::AbstractArray{Int,2})
    r = 0
    x = 1
    grid = permutedims(grid)
    for i ∈ eachindex(grid)
        r += grid[i] * x
        x *= 2
    end
    return r
end

function draw(grid::AbstractArray{T,2}) where {T}
    display(grid); println()
end

function part1(init_grid::AbstractArray{Int,2})
    grid = copy(init_grid)
    states = Set(rating(grid))
    while true
        update_grid!(grid)
        r = rating(grid)
        if r ∈ states
            return r
        else
            union!(states, [r])
        end
    end
end

function main()
    grid = load_data("input24.txt")
    draw(grid)
    println("PART 1: ", part1(grid))
end

main()
