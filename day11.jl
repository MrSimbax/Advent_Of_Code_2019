include("IntCode.jl")
using .IntCode

using OffsetArrays

function turn(dir, turndir)
    if turndir == 0
        dir *= 1im
    elseif turndir == 1
        dir *= -1im
    else
        error("Bad turndir: $turndir")
    end
end

function draw(points)
    coords = keys(points)
    
    (min_x, max_x) = extrema(v->v[1], coords)
    (min_y, max_y) = extrema(v->v[2], coords)
    
    image = fill(0, max_y - min_y + 1, max_x - min_x + 1)
    image2 = OffsetArray(image, min_y:max_y, min_x:max_x)
    for v ∈ coords
        image2[v[2],v[1]] = points[v]
    end
    
    for y in max_y:-1:min_y
        for x in min_x:max_x
            c = image2[y,x]
            if c == 1
                print('█')
            else
                print(' ')
            end
        end
        println()
    end
end

function main()
    srccode = read_src("input11.txt")
    
    for part in 1:2
        points = Dict{Vector{Int},Int}()
        dir = 0 + 1im
        pos = [0, 0]
        in = Array{Int,1}()
        out = Array{Int,1}()
        program = Program(copy(srccode), in, out)
        if part == 2
            points[pos] = 1
        end
        while !program.halted
            push!(in, get(points, pos, 0))
            run_program!(program)
            color = pop!(out)
            turndir = pop!(out)
            points[pos] = color
            dir = turn(dir, turndir)
            pos += [real(dir), imag(dir)]
        end
        if part == 1
            println("PART 1: ", length(keys(points)))
        else
            println("PART 2: ")
            draw(points)
        end
    end
end

main()
