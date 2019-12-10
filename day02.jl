function run_program!(program::Array{Int,1})
    head = 1
    while head < length(program)
        opcode = program[head]
        pos1 = program[head + 1] + 1
        pos2 = program[head + 2] + 1
        pos3 = program[head + 3] + 1
        a = program[pos1]
        b = program[pos2]
        if opcode == 1
            program[pos3] = a + b
        elseif opcode == 2
            program[pos3] = a * b
        elseif opcode == 99
            break
        else
            error("Bad opcode at position $head: $opcode")
        end
        head += 4
    end
end

function main()
    open("input02.txt", "r") do inputfile
        program = [parse(Int, x) for x in split(strip(read(inputfile, String)), ",")]
        
        # part 1
        program1 = copy(program)
        program1[2] = 12
        program1[3] = 2
        run_program!(program1)
        println(program1[1])
        
        # part 2
        for noun in 0:99
            for verb in 0:99
                program2 = copy(program)
                program2[2] = noun
                program2[3] = verb
                run_program!(program2)
                if program2[1] == 19690720
                    println(100 * noun + verb)
                    break
                end
            end
        end
    end
end

main()
