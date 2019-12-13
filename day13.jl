include("IntCode.jl")
using .IntCode

using OffsetArrays

struct Tile
    x::Int
    y::Int
    tile_id::Int
end

function draw(grid)
    io = IOBuffer()
    for y in 0:(size(grid, 1) - 1)
        for x in 0:(size(grid, 2) - 1)
            c = grid[y,x]
            if c == 0
                print(io, ' ')
            elseif c == 1
                print(io, '▧')
            elseif c == 2
                print(io, '■')
            elseif c == 3
                print(io, '▬')
            elseif c == 4
                print(io, '●')
            else
                error("Bad tile at ($x, $y): $c")
            end
        end
        println(io)
    end
    println(String(take!(io)))
end

function main()
    srccode = read_src("input13.txt")
    
    # Part 1
    in = Array{Int,1}()
    out = Array{Int,1}()
    program = Program(copy(srccode), in, out)
    run_program!(program)
    tiles = Vector{Tile}()
    while !isempty(out)
        x = pop!(out)
        y = pop!(out)
        tile_id = pop!(out)
        push!(tiles, Tile(x, y, tile_id))
    end
    max_x = maximum(t->t.x, tiles)
    max_y = maximum(t->t.y, tiles)
    
    raw_grid = fill(0, max_y + 1, max_x + 1)
    grid = OffsetArray(raw_grid, 0:max_y, 0:max_x)
    for t ∈ tiles
        grid[t.y,t.x] = t.tile_id
    end
    println("PART 1: ", count(==(2), grid))
    draw(grid)
    
    # Part 2

    # Get initial data for AI
    pad_pos_x = findfirst(t->t == 3, grid)
    ball_pos_x = findfirst(t->t == 4, grid)

    # Reset grid
    raw_grid = fill(0, max_y + 1, max_x + 1)
    grid = OffsetArray(raw_grid, 0:max_y, 0:max_x)
    
    # Insert coins
    srccode[1] = 2

    # Set up
    in = Array{Int,1}()
    out = Array{Int,1}()
    program = Program(copy(srccode), in, out)

    score = -1
    t = 1
    while !program.halted
        # handle input
        joystick = 0
        if pad_pos_x < ball_pos_x
            joystick = 1
        elseif ball_pos_x < pad_pos_x
            joystick = -1
        end

        push!(in, joystick)
        
        run_program!(program)
        while !isempty(out)
            tile = Tile(pop!(out), pop!(out), pop!(out))
            if tile.x == -1 && tile.y == 0
                score = tile.tile_id
            else
                grid[tile.y,tile.x] = tile.tile_id
            end
            if tile.tile_id == 3
                pad_pos_x = tile.x
            elseif tile.tile_id == 4
                ball_pos_x = tile.x
            end
        end

        t += 1

        run(`cmd /c cls`)
        draw(grid)
        println(score)
        sleep(1 / 30)
    end
end

main()
