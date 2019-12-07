mutable struct Node
    name::String
    children::Array{Node,1}
    parent::Union{Node,Nothing}
end

Node(name) = Node(name, [], nothing)

const Tree = Dict{String,Node}

function read_tree(filename::String)
    open(filename, "r") do inputfile
        T = Tree()
        for line in eachline(inputfile)
            edge = split(line, ")")
            parent = get!(T, edge[1], Node(edge[1]))
            child = get!(T, edge[2], Node(edge[2]))
            push!(parent.children, child)
            child.parent = parent
        end
        return T
    end
end

function find_depth(T::Tree)
    depth = Dict([(v, 0) for (v, _) in T])
    Q = [T["COM"]]
    while !isempty(Q)
        v = pop!(Q)
        for c in v.children
            depth[c.name] = depth[v.name] + 1
            pushfirst!(Q, c)
        end
    end
    return depth
end

function find_common_ancestor(a::Node, b::Node, depth::Dict{String,Int})
    depth_a = depth[a.name]
    depth_b = depth[b.name]
    while depth_a > depth_b
        a = a.parent
        depth_a -= 1
    end
    while depth_b > depth_a
        b = b.parent
        depth_b -= 1
    end
    while a != b
        a = a.parent
        b = b.parent
        depth_a -= 1
        depth_b -= 1
    end
    return a
end

function main()
    T = read_tree("input6.txt")
    depth = find_depth(T)
    part1 = sum(values(depth))
    println("PART 1: $(part1)")
    
    a = find_common_ancestor(T["YOU"], T["SAN"], depth)
    part2 = depth["YOU"] - depth[a.name] + depth["SAN"] - depth[a.name] - 2
    println("PART 2: $(part2)")
end

main()
