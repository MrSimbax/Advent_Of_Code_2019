module IntCode

using OffsetArrays

export Program
export run_program!
export read_src

mutable struct Program
    raw_memory::Array{Int,1} # memory
    memory::OffsetArray{Int,1} # memory indexed from 0
    
    in::Array{Int,1} # input queue
    out::Array{Int,1} # output queue

    ip::Int # instruction pointer
    rb::Int # relative base
    halted::Bool # did the program halt

    offset::Int # current instruction parameter offset
    pmodes::Array{Int,1} # current parameter modes
end

Program(srccode, in, out) = Program(srccode,
    OffsetVector(srccode, 0:(length(srccode) - 1)),
    in,
    out,
    0,
    0, 
    false,
    0,
    [])

# Memory access functions
function expand_memory!(program::Program, pos)
    if pos >= length(program.memory)
        # append!(program.raw_memory, zeros(Int, pos - length(program.raw_memory) + 1))
        resize!(program.raw_memory, pos + 1)
        @views fill!(program.raw_memory[(length(program.memory) + 1):end], 0)
        program.memory = OffsetVector(program.raw_memory, 0:(length(program.raw_memory) - 1))
    end
end

function memget!(program::Program, pos)
    expand_memory!(program, pos)
    return program.memory[pos]
end

function memset!(program::Program, pos, value)
    expand_memory!(program, pos)
    program.memory[pos] = value
end

# Reading/writing parameters
function load!(program::Program)
    param = memget!(program, program.ip + program.offset)
    pmode = get(program.pmodes, program.offset, 0)
    program.offset += 1

    if pmode == 0
        # position mode
        return memget!(program, param)
    elseif pmode == 1
        # immediate mode
        return param
    elseif pmode == 2
        # relative mode
        return memget!(program, param + program.rb)
    else
        error("Bad parameter mode for load: $pmode")
    end
end

function store!(program::Program, value)
    param = memget!(program, program.ip + program.offset)
    pmode = get(program.pmodes, program.offset, 0)
    program.offset += 1

    if pmode == 0
        # position mode
        memset!(program, param, value)
    elseif pmode == 2
        # relative mode
        memset!(program, param + program.rb, value)
    else
        error("Bad parameter mode for store: $pmode")
    end
end

function decode_opcode(opcode)
    pmodes = Array{Int,1}()
    if opcode > 99
        pmodes = Int.(digits(div(opcode, 100)))
        opcode = mod(opcode, 100)
    end
    return opcode, pmodes
end

function run_program!(program::Program)::Program
    while program.ip < length(program.memory)
        opcode, program.pmodes = decode_opcode(memget!(program, program.ip))
        program.offset = 1
        if opcode == 1
            # add
            store!(program, load!(program) + load!(program))
            program.ip += 4
        elseif opcode == 2
            # mult
            store!(program, load!(program) * load!(program))
            program.ip += 4
        elseif opcode == 3
            # input
            if isempty(program.in)
                return program
            end
            store!(program, pop!(program.in))
            program.ip += 2
        elseif opcode == 4
            # output
            pushfirst!(program.out, load!(program))
            program.ip += 2
        elseif opcode == 5
            # jump-if-true
            if load!(program) != 0
                program.ip = load!(program)
            else
                program.ip += 3
            end
        elseif opcode == 6
            # jump-if-false
            if load!(program) == 0
                program.ip = load!(program)
            else
                program.ip += 3
            end
        elseif opcode == 7
            # less than
            if load!(program) < load!(program)
                store!(program, 1)
            else
                store!(program, 0)
            end
            program.ip += 4
        elseif opcode == 8
            # equals
            if load!(program) == load!(program)
                store!(program, 1)
            else
                store!(program, 0)
            end
            program.ip += 4
        elseif opcode == 9
            # adjust rb
            program.rb += load!(program)
            program.ip += 2
        elseif opcode == 99
            # halt
            break
        else
            error("Bad opcode at position $(program.ip): $opcode")
        end
    end
    program.halted = true
    return program
end

function read_src(filename)
    open(filename) do inputfile
        [parse(Int, x) for x in split(strip(read(inputfile, String)), ",")]
    end
end

end
