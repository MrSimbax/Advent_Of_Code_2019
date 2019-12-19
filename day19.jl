include("IntCode.jl")
using .IntCode

using OffsetArrays

function draw(grid::AbstractArray{Char,2}; to::IO = stdout)
    io = IOBuffer()
    for y ∈ axes(grid, 1)
        for x ∈ axes(grid, 2)
            print(io, grid[y,x])
        end
        println(io)
    end
    println(to, String(take!(io)))
end

function get_status(src::Vector{Int}, in::Vector{Int})
    out = Vector{Int}()
    program = Program(copy(src), copy(in), out)
    run_program!(program)
    status = pop!(out)
end

function scan_grid(from::Vector{Int}, to::Vector{Int})
    srccode = read_src("input19.txt")
    grid = OffsetArray(fill('.', to[1] - from[1] + 1, to[2] - from[2] + 1), from[1]:to[1], from[2]:to[2])
    for y ∈ axes(grid, 1)
        for x ∈ axes(grid, 2)
            if get_status(srccode, [y,x]) == 1
                grid[y,x] = '#'
            end
        end
    end
    return grid
end

function find_square(size::Int)
    src = read_src("input19.txt")
    step_x = 1
    step_y = 1

    # Find initial top right point
    top_right = [0, size - 1]
    while get_status(src, top_right) != 1
        top_right[1] += step_y
    end
    while get_status(src, top_right) == 1
        top_right[2] += step_x
    end
    top_right[2] -= step_x

    # Go down the beam until you find a place for squaree
    while true
        bottom_left = [top_right[1] + size - 1, top_right[2] - size + 1]
        if get_status(src, bottom_left) == 1
            return top_right
        end
        top_right[1] += step_y
        while get_status(src, top_right) == 1
            top_right[2] += step_x
        end
        top_right[2] -= step_x
    end
end

function main()
    grid = scan_grid([0,0], [49,49])
    draw(grid)
    println("PART 1: ", count(==('#'), grid))
    @time scan_grid([0,0], [49,49])

    pos = find_square(100)
    pos[2] -= 99
    println("PART 2: ", pos[2] * 10000 + pos[1])
    @time find_square(100)
end

main()
