function main()
    open("input1.txt", "r") do inputfile
        all_fuel = 0
        for line in eachline(inputfile)
            mass = parse(Int, line)
            fuel = floor(Int, mass / 3) - 2
            # part 2
            while fuel > 0
                all_fuel += fuel
                fuel = floor(Int, fuel / 3) - 2
            end
        end
        println(all_fuel)
    end
end

main()
