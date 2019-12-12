mutable struct Moon
    pos::Vector{Int}
    vel::Vector{Int}
end

function Base.show(io::IO, moon::Moon)
    print("pos=<x=", moon.pos[1], ", y=", moon.pos[2], ", z=", moon.pos[3], ">, ",
          "vel=<x=", moon.vel[1], ", y=", moon.vel[2], ", z=", moon.vel[3], ">")
end

function load_data(filename::String)
    open(filename, "r") do inputfile
        ret = Vector{Vector{Int}}()
        for line ∈ eachline(inputfile)
            m = match(r"^<\s*x=(-?\d+)\s*,\s*y=(-?\d+)\s*,\s*z=(-?\d+)\s*>$", strip(line))
            push!(ret, map(a->parse(Int, a), m.captures))
        end
        ret
    end
end

function simulate_gravity!(moons::Vector{Moon})
    for i ∈ 1:(length(moons) - 1)
        for j ∈ (i + 1):length(moons)
            for axis in 1:3
                c = cmp(moons[j].pos[axis], moons[i].pos[axis])
                moons[i].vel[axis] += c
                moons[j].vel[axis] -= c
            end
        end
    end
end

function update_positions!(moons::Vector{Moon})
    for moon ∈ moons
        moon.pos += moon.vel
    end
end

function potential_energy(moon::Moon)
    sum(abs, moon.pos)
end

function kinetic_energy(moon::Moon)
    sum(abs, moon.vel)
end

function total_energy(moon::Moon)
    potential_energy(moon) * kinetic_energy(moon)
end

function print_moons(t::Int, moons::Vector{Moon})
    println("After ", t, " steps:")
    for moon ∈ moons
        println(moon)
    end
    println()
end

function axis_moons_not_equal(moon1::Moon, moon2::Moon, axis::Int)
    moon1.pos[axis] != moon2.pos[axis] || moon1.vel[axis] != moon2.vel[axis]
end

function axis_all_moons_equal(moons1::Vector{Moon}, moons2::Vector{Moon}, axis::Int)
    for i ∈ eachindex(moons1)
        if axis_moons_not_equal(moons1[i], moons2[i], axis)
            return false
        end
    end
    return true
end

function part1(init_moons)
    moons = deepcopy(init_moons)
    T = 1000
    for t ∈ 1:T
        simulate_gravity!(moons)
        update_positions!(moons)
    end
    println("PART 1: ", sum(total_energy, moons))
end

function part2(init_moons)
    moons = deepcopy(init_moons)
    t = 1
    cycle_x = 0
    cycle_y = 0
    cycle_z = 0
    while cycle_x == 0 || cycle_y == 0 || cycle_z == 0
        simulate_gravity!(moons)
        update_positions!(moons)
        
        if cycle_x == 0 && axis_all_moons_equal(init_moons, moons, 1)
            cycle_x = t
        end
        if cycle_y == 0 && axis_all_moons_equal(init_moons, moons, 2)
            cycle_y = t
        end
        if cycle_z == 0 && axis_all_moons_equal(init_moons, moons, 3)
            cycle_z = t
        end

        t += 1
    end
    println("PART 2: ", lcm(cycle_x, cycle_y, cycle_z))
end

function main()
    init_moons = map(pos->Moon(pos, [0,0,0]), load_data("input12.txt"))
    print_moons(0, init_moons)

    part1(init_moons)
    part2(init_moons)
end

main()
