using LinearAlgebra

function load_map(filename)
    open(filename, "r") do file
        M = collect.(split(strip(read(file, String)), '\n'))
        map(c->c == '.' ? -1 : 0, reshape(vcat(M...), length(M), length(first(M))))
    end
end

function calc_slope((x1, y1), (x2, y2))
    dy = y2 - y1
    dx = x2 - x1
    g = gcd(dy, dx) # gcd ensures the slope is unique
    dy = div(dy, g)
    dx = div(dx, g)
    (dy, dx)
end

"""
(x0,y0) -- origin

returns (angle, distance)
"""
function polar((x0, y0), (x, y))
    dy = y0 - y # flip y axis
    dx = x - x0
    r = norm([dx, dy])
    g = gcd(dy, dx) # this ensures the result is the same for the same slope
    # minus π / 2 because we want the angle 0 to point up
    # minus because we want clockwise instead of anticlockwise direction
    a = - (atan(div(dy, g), div(dx, g)) - π / 2)
    if a < 0 # adjust negative angles so that the result is between [0,2π)
        a += 2 * π
    end
    return (a, r)
end

function find_best_location(amap, asteroids)
    # Bruteforce
    # Count unique slopes for all segments between any two asteroids
    for i ∈ 1:length(asteroids)
        (x1, y1) = asteroids[i]
        slopes = Set{Tuple{Int,Int}}()
        for j ∈ 1:length(asteroids)
            (x2, y2) = asteroids[j]
            if (x1, y1) == (x2, y2)
                continue
            end
            
            slope = calc_slope((x1, y1), (x2, y2))
            slopes = union!(slopes, [slope])
        end
        amap[x1,y1] += length(slopes)
    end
    Tuple(argmax(amap))
end

function laser_sort((x0, y0), asteroids)
    # Sort lexicographically by (angle, distance) first
    Q = sort(asteroids, by = o->polar((x0, y0), o))
    
    # Now split it into sorted by angle layers with the following properties:
    # * asteroids in the same line of sight are not in the same layer
    # * an asteroid in a layer is further than
    #   any asteroid in the same line of sight which is in an earlier layer
    sorted = []
    while !isempty(Q)
        o = popfirst!(Q)
        push!(sorted, o)
        (a, r) = polar((x0, y0), o)
        # skip all asteroids behind `o`
        Q2 = []
        while !isempty(Q)
            o1 = first(Q)
            (a1, r1) = polar((x0, y0), o1)
            if a == a1
                popfirst!(Q)
                push!(Q2, o1)
            else
                break
            end
        end
        append!(Q, Q2)
    end
    sorted
end

function main()
    amap = load_map("input10.txt")
    asteroids = [(x, y) for x ∈ 1:size(amap, 1) for y ∈ 1:size(amap, 2) if amap[x,y] >= 0]
    
    (x0, y0) = find_best_location(amap, asteroids)
    println("PART 1: ", amap[x0,y0])
    
    filter!(!=((x0, y0)), asteroids)
    (x, y) = laser_sort((x0, y0), asteroids)[200]
    println("PART 2: $((x - 1) * 100 + (y - 1))")
end

main()
