include("Grid.jl")
include("IntCode.jl")

using .GridModule
using .IntCode

using OffsetArrays

function draw(grid::AbstractArray{Int,2})
    io = IOBuffer()
    for y ∈ axes(grid, 1)
        for x ∈ axes(grid, 2)
            print(io, Char(grid[y,x]))
        end
        println(io)
    end
    println(String(take!(io)))
end

function in_bounds(grid::AbstractArray{Int,2}, pos::Vector{Int})
    pos[1] ∈ axes(grid, 1) && pos[2] ∈ axes(grid, 2)
end

function get_neighbours(pos::Vector{Int})
    [
        [ pos[1] + 1, pos[2]     ],
        [ pos[1],     pos[2] + 1 ],
        [ pos[1] - 1, pos[2]     ],
        [ pos[1],     pos[2] - 1 ]
    ]
end

function get_neighbours_in_bounds(grid::AbstractArray{Int,2}, pos::Vector{Int})
    filter!(p->in_bounds(grid, p), get_neighbours(pos))
end

function load_grid(srccode::Vector{Int})
    in = Vector{Int}()
    out = Vector{Int}()
    program = Program(copy(srccode), in, out)
    run_program!(program)
    grid = Grid(default = Int('.'))
    x = 0
    y = 0
    width = 0
    height = 0
    while !isempty(out)
        c = pop!(out)
        if Char(c) == '\n'
            if width == 0
                width = x
            end
            x = 0
            y += 1
        else
            set_tile!(grid, [y,x], c)
            x += 1
        end
    end
    height = y
    grid = OffsetArray(grid.grid[0:(height - 1),0:(width - 1)], 0:(height - 1), 0:(width - 1))
    return grid
end

function part1(grid::AbstractArray{Int,2})
    S = 0
    for y ∈ axes(grid, 1)
        for x ∈ axes(grid, 2)
            pos = [y,x]
            if (Char(grid[pos...]) == '#' &&
               all(pos->Char(grid[pos...]) == '#', get_neighbours_in_bounds(grid, pos)))

                S += y * x
            end
        end
    end
    return S
end

function load_movement_functions(filename)
    open(filename, "r") do file
        ret = Vector{Int}()
        while !eof(file)
            pushfirst!(ret, Int(read(file, Char)))
        end
        return ret
    end
end

function part2!(srccode::Vector{Int}, grid::AbstractArray{Int,2}; feed = false)
    srccode[1] = 2
    in = load_movement_functions("day17code.txt")
    pushfirst!(in, Int(feed ? 'y' : 'n'))
    pushfirst!(in, Int('\n'))
    # println(Char.(in))
    out = Vector{Int}()
    program = Program(copy(srccode), in, out)
    run_program!(program)
    if feed
        while length(out) > 1
            print("\033[2H\033[2J")
            print_grid(out)
            sleep(1 / 20)
        end
    end
    return pop!(out)
end

function print_grid(out::Vector{Int})
    io = IOBuffer()
    prevc = ' '
    while true
        c = Char(pop!(out))
        if c == '\n' && prevc == '\n'
            break
        end
        prevc = c
        print(io, c)
    end
    println(String(take!(io)))
end

function fwd(grid::AbstractArray{Int,2}, pos, dir)
    cnt = 0
    pos = copy(pos)
    while true
        pos += [imag(dir), real(dir)]
        if !in_bounds(grid, pos) || Char(grid[pos...]) != '#'
            break
        end
        cnt += 1
    end
    pos -= [imag(dir), real(dir)]
    (cnt, pos)
end

function move(grid::AbstractArray{Int,2}, pos, dir)
    # try forward
    cnt, newpos = fwd(grid, pos, dir)
    if cnt != 0
        return (newpos, dir, "$cnt,")
    end
    # try right
    dir *= 1im
    cnt, newpos = fwd(grid, pos, dir)
    if cnt != 0
        return (newpos, dir, "R,$cnt,")
    end
    # try left
    dir *= -1
    cnt, newpos = fwd(grid, pos, dir)
    if cnt != 0
        return (newpos, dir, "L,$cnt,")
    end
    # reached the end
    dir *= 1im
    (pos, dir, "")
end

function generate_program(grid::AbstractArray{Int,2})
    start_pos = findfirst(==(Int('^')), grid)
    pos = [start_pos[1], start_pos[2]]
    dir = -1im
    # println("pos=$pos")
    program = ""
    while true
        # grid[pos...] = '#'
        pos, dir, mv = move(grid, pos, dir)
        # println(pos, ", ", dir, ", ", mv)
        # grid[pos...] = '^'
        # draw(grid)
        # sleep(1)
        if isempty(mv)
            break
        end
        program *= mv
    end
    program
end

function main()
    srccode = read_src("input17.txt")
    grid = load_grid(srccode)
    draw(grid)

    part2 = part2!(srccode, grid, feed = true)
    println("PART 1: ", part1(grid))
    println("PROGRAM: ", generate_program(grid))
    println("PART 2: ", part2)
end

main()
