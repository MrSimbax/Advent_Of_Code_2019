# Vertex in DAG of all reactions
struct Chemical
    name::String

    products::Vector{Chemical}
    product_amounts::Vector{Int}
    required::Vector{Int}
end

Chemical(name::Union{String,SubString{String}}) = Chemical(name,
    Vector{Int}(), Vector{Int}(), Vector{Int}())

function load_data(filename)
    open(filename, "r") do file
        chemicals = Dict{String,Chemical}()
        for line ∈ eachline(file)
            raw_reaction = split(strip(line), "=>")

            raw_output = split(strip(raw_reaction[2]))
            output_amount = parse(Int, raw_output[1])
            output = get!(chemicals, raw_output[2], Chemical(raw_output[2]))

            for raw_chem ∈ split.(strip.(split(raw_reaction[1], ",")))
                chem = get!(chemicals, raw_chem[2], Chemical(raw_chem[2]))
                push!(chem.products, output)
                push!(chem.product_amounts, output_amount)
                push!(chem.required, parse(Int, raw_chem[1]))
            end
        end
        chemicals
    end
end

function find_required_amount(input::Chemical, cache::Dict{String,Int})
    if get(cache, input.name, 0) > 0
        return cache[input.name]
    end

    count = 0
    for (product, amount, required) ∈ zip(input.products, input.product_amounts, input.required)
        count += required * ceil(Int, find_required_amount(product, cache) / amount)
    end
    cache[input.name] = count
    return count
end

function find_maximum_amount(input::Chemical, max_ore::Int, min_fuel::Int)
    fuel = min_fuel
    max_fuel = fuel
    while true
        cache = Dict{String,Int}()
        cache["FUEL"] = fuel
        ore = find_required_amount(input, cache)
        if ore > max_ore
            max_fuel = fuel
            break
        else
            min_fuel = fuel
            fuel *= 2
        end
    end

    while min_fuel < max_fuel
        mid = div(min_fuel + max_fuel, 2)
        cache = Dict{String,Int}()
        cache["FUEL"] = mid
        ore = find_required_amount(input, cache)
        if ore > max_ore
            max_fuel = mid - 1
        elseif ore == max_ore
            return mid
        else
            min_fuel = mid + 1
        end
    end
    return max_fuel
end

function main()
    chemicals = load_data("input14.txt")

    cache = Dict{String,Int}()
    cache["FUEL"] = 1
    println("PART 1: ", find_required_amount(chemicals["ORE"], cache))
    
    cache = Dict{String,Int}()
    cache["FUEL"] = 1
    @time find_required_amount(chemicals["ORE"], cache)

    max_ore = 1000000000000
    min_fuel = div(max_ore, find_required_amount(chemicals["ORE"], cache))
    println("PART 2: ", find_maximum_amount(chemicals["ORE"], max_ore, min_fuel))
    @time find_maximum_amount(chemicals["ORE"], max_ore, min_fuel)
end

main()
