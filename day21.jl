include("IntCode.jl")
using .IntCode

using OffsetArrays

function load_code(filename)
    open(filename, "r") do file
        ret = Vector{Int}()
        while !eof(file)
            pushfirst!(ret, Int(read(file, Char)))
        end
        return ret
    end
end

function run!(srccode::Vector{Int}, springscript_filename::String)
    in = load_code(springscript_filename)
    out = Vector{Int}()
    program = Program(copy(srccode), in, out)
    run_program!(program)
    while length(out) > 1
        print_out(out)
    end
    if !isempty(out)
        return pop!(out)
    else
        return -1
    end
end

function print_out(out::Vector{Int})
    io = IOBuffer()
    prevc = ' '
    while !isempty(out)
        c = Char(pop!(out))
        if c == '\n' && prevc == '\n'
            break
        end
        prevc = c
        print(io, c)
    end
    println(String(take!(io)))
end

function main()
    srccode = read_src("input21.txt")
    println("PART 1: ", run!(srccode, "day21code.txt"))
    println("PART 2: ", run!(srccode, "day21code2.txt"))
end

main()
