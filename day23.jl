include("IntCode.jl")
using .IntCode

using OffsetArrays

function run_network(srccode::Vector{Int}, N::Int; part::Int = 1)
    computers = OffsetArray([Program(srccode) for i ∈ 1:N], 0:(N - 1))

    # Boot them up
    for i ∈ eachindex(computers)
        pushfirst!(computers[i].in, i)
        run_program!(computers[i])
    end

    NAT = Vector{Int}()

    # Run them
    i = 0
    idle_count = 0
    prev_Y = -1
    while true
        computer = computers[i]

        no_input = isempty(computer.in)
        if no_input
            pushfirst!(computer.in, -1)
        end

        # println("computer[$i]")
        # println("before:")
        # println("   in = $(computer.in)")
        # println("  out = $(computer.out)")
        run_program!(computer)
        # println("after:")
        # println("   in = $(computer.in)")
        # println("  out = $(computer.out)")
        
        no_output = isempty(computer.out)
        idle = no_input && no_output
        idle_count = idle ? idle_count + 1 : 0
        if idle_count == N
            X = pop!(NAT)
            Y = pop!(NAT)
            if part == 2 && Y == prev_Y
                return Y
            end
            prev_Y = Y
            pushfirst!(computers[0].in, X)
            pushfirst!(computers[0].in, Y)
            i = 0
            continue
        end

        while !isempty(computer.out)
            address = pop!(computer.out)
            X = pop!(computer.out)
            Y = pop!(computer.out)
            if address == 255
                if part == 1
                    return Y 
                else
                    NAT = [Y, X]
                    continue
                end
            end
            recipient = computers[address]
            pushfirst!(recipient.in, X)
            pushfirst!(recipient.in, Y)
        end

        i += 1
        if i >= N
            i = 0
        end
    end
end

function main()
    srccode = read_src("input23.txt")
    println("PART 1: ", run_network(srccode, 50, part = 1))
    println("PART 2: ", run_network(srccode, 50, part = 2))
end

main()
