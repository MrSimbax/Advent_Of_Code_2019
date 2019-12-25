include("IntCode.jl")
using .IntCode

function run(srccode::Vector{Int})
    program = Program(srccode)
    while !program.halted
        run_program!(program)
        while length(program.out) > 1
            print_out(program.out)
        end
        program.in = [Int('\n'); reverse(Int.(collect(readline())))]
        # println(program.in)
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
    srccode = read_src("input25.txt")
    run(srccode)
end

"""
      __    __     ______     ______
     /\ "-./  \   /\  __ \   /\  == \
     \ \ \-./\ \  \ \  __ \  \ \  _-/
      \ \_\ \ \_\  \ \_\ \_\  \ \_\
       \/_/  \/_/   \/_/\/_/   \/_/

                +-------+                     +-----------+              +-------------+
                |Stables|                     |Engineering+--------------+Crew Quarters|
                +---+---+ (X) infinite loop   +-----+-----+ hypercube    +------+------+ sand
                    |                               |                           |
                    |                               |                           |
              +-----+-----+                      +--+---+                 +-----+----+
              |Observatory+----------------------+Arcade|                 |Navigation|
              +-----------+                      +---+--+ spool of cat6   +----------+ antenna
                                                     |
          +-------+                                  |
          |Hallway|                                  |
          +---+---+ (X) giant electromagnet          |
              |                                      |
        +-----+-----+                           +----+---+
        |Hull Breach+---------------------------+Passages|
        +-----+-----+                           +----+---+ mouse
              |                                      |
        +-----+-----+                                |
        |Science Lab|                                |
        +-----------+ astronaut ice cream            |
                                                     |
      +--------+  +-------------+              +-----+-----+
      |Sick Bay+--+Gift Wrapping+--------------+Warp Drive |
      +--------+  |Center       |              |Maintenance|
                  +-------+-----+ boulder      +-----+-----+ mutex
                          |                          |
                     +----+---+                  +---+---+
                     |Holodeck|                  |Kitchen|
                     +----+---+ (X) escape pod   +-------+
                          |
                  +-------+-----+
                  |Hot Chocolate|
                  |Fountain     |
                  +-------+-----+ (X) photons
                          |
      +-------+      +----+---+
      |Storage+------+Corridor|
      +---+---+      +--------+ (X) molten lava
          |
     +----+-----+
     |Security  |
     |Checkpoint|
     +----+-----+
          |
        -----
          |
 +--------+---------+
 |Pressure-Sensitive|
 |Floor             |
 +------------------+

SOLUTION: sand, mouse, astronaut ice cream, boulder
"""

main()
