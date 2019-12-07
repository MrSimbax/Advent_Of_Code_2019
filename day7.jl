"""
Returns instruction parameter value from the `program`.

`param` is treated as:
    * position of the value relative to 0 if `pmode` == 0
    * the value if `pmode` == 1
"""
function get_parameter(program::Array{Int,1}, param::Int, pmode::Int)::Int
    if pmode == 0
        # position mode
        return program[param + 1]
    elseif pmode == 1
        # immediate mode
        return param
    else
        error("Bad parameter mode: $pmode")
    end
end

"""
Decodes raw opcode from a program.

Returns:
    * decoded opcode (the least significant two digits of the given raw `opcode`)
    * array of parameter modes based on the rest of digits
"""
function decode_opcode(opcode::Int)
    pmodes = []
    if opcode > 99
        pmodes = Int.(digits(div(opcode, 100)))
        opcode = mod(opcode, 100)
    end
    return opcode, pmodes
end

"""
Runs the given `program` starting from instruction at index `ip` (by default 1).
The program is modified during the run.

`stdin` is a queue with input to the program.
`stdout` is a queue with output of the program.

The **returned** value is:
    * 0 if program ended normally (reached halt instruction
      or instruction pointer is out of bounds)
    * current `ip` if program is waiting for input but `stdin` is empty;
      run the modified program again with this `ip` after filling `stdin`
      to resume execution

**Implementation note:** the program itself uses indexing starting from 0, not 1,
so the positions read from the program need to be shifted by 1.
"""
function run_program!(program::Array{Int,1}, stdin::Array{Int,1}, stdout::Array{Int,1}, ip = 1)::Int
    while ip <= length(program)
        opcode, pmodes = decode_opcode(program[ip])
        if opcode == 1
            # add
            a = get_parameter(program, program[ip + 1], get(pmodes, 1, 0))
            b = get_parameter(program, program[ip + 2], get(pmodes, 2, 0))
            outpos = program[ip + 3] + 1
            program[outpos] = a + b
            ip += 4
        elseif opcode == 2
            # mult
            a = get_parameter(program, program[ip + 1], get(pmodes, 1, 0))
            b = get_parameter(program, program[ip + 2], get(pmodes, 2, 0))
            outpos = program[ip + 3] + 1
            program[outpos] = a * b
            ip += 4
        elseif opcode == 3
            # input
            pos = program[ip + 1] + 1
            if isempty(stdin)
                return ip
            end
            program[pos] = pop!(stdin)
            ip += 2
        elseif opcode == 4
            # output
            pos = program[ip + 1] + 1
            pushfirst!(stdout, program[pos])
            ip += 2
        elseif opcode == 5
            # jump-if-true
            a = get_parameter(program, program[ip + 1], get(pmodes, 1, 0))
            jpos = get_parameter(program, program[ip + 2], get(pmodes, 2, 0))
            if a != 0
                ip = jpos + 1
            else
                ip += 3
            end
        elseif opcode == 6
            # jump-if-false
            a = get_parameter(program, program[ip + 1], get(pmodes, 1, 0))
            jpos = get_parameter(program, program[ip + 2], get(pmodes, 2, 0))
            if a == 0
                ip = jpos + 1
            else
                ip += 3
            end
        elseif opcode == 7
            # less than
            a = get_parameter(program, program[ip + 1], get(pmodes, 1, 0))
            b = get_parameter(program, program[ip + 2], get(pmodes, 2, 0))
            pos = program[ip + 3] + 1
            if a < b
                program[pos] = 1
            else
                program[pos] = 0
            end
            ip += 4
        elseif opcode == 8
            # equals
            a = get_parameter(program, program[ip + 1], get(pmodes, 1, 0))
            b = get_parameter(program, program[ip + 2], get(pmodes, 2, 0))
            pos = program[ip + 3] + 1
            if a == b
                program[pos] = 1
            else
                program[pos] = 0
            end
            ip += 4
        elseif opcode == 99
            # halt
            break
        else
            error("Bad opcode at position $ip: $opcode")
        end
    end
    return 0
end

"""
Runs the given `programs` in a loop until all of them halt.
`inputs` and `outputs` are input and output queues for the programs.
All the arguments should be arrays of arrays of ints. 

If a program is waiting for input and will not be provided with one,
it will loop forever.
"""
function run_programs(programs, inputs, outputs)
    n = length(programs)
    pid = 1
    programs_running = n
    ips = fill(1, n)
    while programs_running > 0
        if ips[pid] > 0
            ips[pid] = run_program!(programs[pid], inputs[pid], outputs[pid], ips[pid])
            if ips[pid] == 0
                programs_running -= 1
            end
        end

        pid += 1
        if pid > n
            pid = 1
        end
    end
end

"""
Returns the next permutation of the array `p` in lexicographical order.
If `p` is the highest permutation it returns the identity permutation.

Implementation note: the code is not optimally written but should be more readable.
"""
function next_permutation!(p)
    n = length(p)
    A = [i for i in 1:(n - 1) if p[i] < p[i + 1]]
    if isempty(A)
        reverse!(p)
    else
        k = maximum(A)
        
        # There's no argmin(f, [itr]) in Julia unfortunataly so here's ugly workaround.
        lv = minimum([p[i] for i in (k + 1):n if p[k] < p[i]])
        l = findfirst(v->v == lv, p)

        p[k], p[l] = p[l], p[k]
        reverse!(p, k + 1)
    end
end

function main()
    open("input7.txt", "r") do inputfile
        program = [parse(Int, x) for x in split(strip(read(inputfile, String)), ",")]

        for part in 1:2
            amplifiers_count = 5
            phase_shifts = if part == 1
                collect(0:4)
            else
                collect(5:9)
            end
            maximum_output = typemin(Int)

            while true
                programs = [copy(program) for i in 1:amplifiers_count]
                inputs = fill(Array{Int,1}(), amplifiers_count)
                outputs = fill(Array{Int,1}(), amplifiers_count)

                inputs[1] = outputs[5] = [0, phase_shifts[1]]
                inputs[2] = outputs[1] = [phase_shifts[2]]
                inputs[3] = outputs[2] = [phase_shifts[3]]
                inputs[4] = outputs[3] = [phase_shifts[4]]
                inputs[5] = outputs[4] = [phase_shifts[5]]

                run_programs(programs, inputs, outputs)

                maximum_output = max(maximum_output, first(outputs[5]))
                next_permutation!(phase_shifts)
                if issorted(phase_shifts)
                    break
                end
            end
        
            println("PART $part: $(maximum_output)")
        end
    end
end

main()
