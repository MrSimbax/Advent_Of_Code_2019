function get_parameter(program, param, pmode)
    if pmode == 0
        return program[param + 1]
    elseif pmode == 1
        return param
    else
        println("Bad pmode: $pmode")
        exit(1)
    end
end

function run_program!(program::Array{Int,1})
    ip = 1
    while ip < length(program)
        opcode = program[ip]
        pmodes = []
        if opcode > 99
            pmodes = Int.(digits(opcode)[3:end])
            opcode = mod(opcode, 100)
        end
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
            print("IN: ")
            program[pos] = parse(Int, readline())
            ip += 2
        elseif opcode == 4
            # output
            pos = program[ip + 1] + 1
            print("OUT: ")
            println(program[pos])
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
            println("Bad opcode at position $ip: $opcode")
            exit(1)
        end
    end
end

function main()
    open("input5.txt", "r") do inputfile
        program = [parse(Int, x) for x in split(strip(read(inputfile, String)), ",")]
        run_program!(program)
    end
end

main()
