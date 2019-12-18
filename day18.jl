include("IntCode.jl")

using .IntCode

using OffsetArrays

struct Edge
    path::Vector{Vector{Int}}
    doors::Set{Char}
end

struct Node
    name::Char
    pos::Vector{Int}
    edges::Dict{Char,Edge}
end

Node(name::Char, pos::Vector{Int}) = Node(name, pos, Dict{Char,Edge}())

struct Graph
    grid::AbstractArray{Char,2}
    nodes::Dict{Char,Node}
end

function draw(grid::AbstractArray{Char,2})
    io = IOBuffer()
    for y ∈ axes(grid, 1)
        for x ∈ axes(grid, 2)
            print(io, grid[y,x])
        end
        println(io)
    end
    println(String(take!(io)))
end

function in_bounds(grid::AbstractArray{T,2}, pos::Vector{Int}) where {T}
    pos[1] ∈ axes(grid, 1) && pos[2] ∈ axes(grid, 2)
end

function get_neighbours(pos::Vector{Int})
    [
        [ pos[1] + 1, pos[2]     ],
        [ pos[1],     pos[2] + 1 ],
        [ pos[1] - 1, pos[2]     ],
        [ pos[1],     pos[2] - 1 ]
    ]
end

function get_neighbours_in_bounds(grid::AbstractArray{T,2}, pos::Vector{Int}) where {T}
    filter!(p->in_bounds(grid, p), get_neighbours(pos))
end

function load_grid(filename)
    open(filename, "r") do file
        permutedims(hcat(collect.(String.(split(strip(read(file, String)), '\n')))...))
    end
end

function make_distance_grid(grid::AbstractArray{Char,2}, from::Vector{Int}, walkable::Set{Char} = Set('.'))
    distance_grid = fill(-1, size(grid, 1), size(grid, 2))
    distance_grid[from...] = 0
    Q = [from]
    while !isempty(Q)
        v = pop!(Q)
        dist_v = distance_grid[v...]
        for n ∈ get_neighbours_in_bounds(distance_grid, v)
            if distance_grid[n...] < 0 && grid[n...] ∈ walkable
                distance_grid[n...] = dist_v + 1
                pushfirst!(Q, n)
            end
        end
    end
    return distance_grid
end

function find_the_shortest_path(distance_grid::AbstractArray{Int,2}, from::Vector{Int}, to::Vector{Int})
    path = Vector{Vector{Int}}()
    while from != to
        pushfirst!(path, to)
        N = filter!(n->distance_grid[n...] >= 0, get_neighbours_in_bounds(distance_grid, to))
        if isempty(N)
            return []
        end
        i = argmin(map(n->distance_grid[n...], N))
        to = N[i]
    end
    return path
end

function make_full_graph(grid::AbstractArray{Char,2})
    nodes::Dict{Char,Node} = Dict(map(c->grid[c] => Node(grid[c], [c[1],c[2]]), findall(c->islowercase(c) || c == '@', grid)))
    # display(nodes); println()
    walkable = Set('.')
    walkable = union!(walkable, Char.(Int('a'):Int('z')))
    walkable = union!(walkable, Char.(Int('A'):Int('Z')))
    walkable = union!(walkable, ['@'])
    keys = Set(uppercase.(map(i->grid[i], findall(c->islowercase(c), grid))))
    for from ∈ values(nodes)
        distance_grid = make_distance_grid(grid, from.pos, walkable)
        for to ∈ values(nodes)
            if to == from || to.name == '@'
                continue
            end
            path = find_the_shortest_path(distance_grid, from.pos, to.pos)
            if !isempty(path)
                doors = Set(map(i->grid[path[i]...], findall(p->isuppercase(grid[p...]), path)))
                # Remove doors with no key
                doors = intersect(doors, uppercase.(keys))
                from.edges[to.name] = Edge(path, doors)
            end
        end
    end
    # display(nodes); println()
    return Graph(grid, nodes)
end

function find_reachable_nodes(graph::Graph, from::Node, collected::Set{Char})
    reachable = Vector{Node}()
    for (to, edge) ∈ from.edges
        if to ∉ collected && intersect(edge.doors, uppercase.(collected)) == edge.doors
            push!(reachable, graph.nodes[to])
        end
    end
    return reachable
end

const State = Tuple{Char,Set{Char}}

function the_shortest_hamiltonian_path(graph::Graph, from::Node)
    paths = Dict{State,Int}()
    start = (from.name, Set{Char}())
    paths[start] = 0
    Q = [start]
    i = -1
    while !isempty(Q)
        state = pop!(Q)
        if length(state[2]) != i
            i = length(state[2])
            # println("i=", i)
        end
        node = graph.nodes[state[1]]
        reachable = find_reachable_nodes(graph, node, state[2])
        if isempty(reachable)
            continue
        end
        for next_node ∈ reachable
            next_state = (next_node.name, union(Set(next_node.name), state[2]))
            path = paths[state] + length(node.edges[next_node.name].path)
            if haskey(paths, next_state)
                if path < paths[next_state]
                    paths[next_state] = path
                else
                    # nothing
                end
            else
                # println(next_state)
                # println(path)
                paths[next_state] = path
                pushfirst!(Q, next_state)
            end
        end
    end

    # display(paths); println()

    fullset = setdiff(Set(keys(graph.nodes)), Set('@'))
    min_path_length = typemax(Int)
    for node ∈ filter(k->k != '@', collect(keys(graph.nodes)))
        if haskey(paths, (node, fullset))
            path = paths[(node, fullset)]
            if path < min_path_length
                min_path_length = path
            end
        else
            # println("Not found: ", (node, fullset))
        end
    end

    return min_path_length
end

function part1(grid::AbstractArray{Char,2})
    graph = make_full_graph(grid)
    path = the_shortest_hamiltonian_path(graph, graph.nodes['@'])
    println("PART 1: ", path)
    # println(path)
end

function part2!(grid::AbstractArray{Char,2})
    # prepare grids
    start_pos = findfirst(p->p == '@', grid)
    q1 = [start_pos[1] - 1, start_pos[2] + 1]
    q2 = [start_pos[1] - 1, start_pos[2] - 1]
    q3 = [start_pos[1] + 1, start_pos[2] - 1]
    q4 = [start_pos[1] + 1, start_pos[2] + 1]
    grid[q1...] = '@'
    grid[q2...] = '@'
    grid[q3...] = '@'
    grid[q4...] = '@'
    grid[start_pos] = '#'
    grid[start_pos[1], start_pos[2] - 1] = '#'
    grid[start_pos[1], start_pos[2] + 1] = '#'
    grid[start_pos[1] - 1,start_pos[2]] = '#'
    grid[start_pos[1] + 1,start_pos[2]] = '#'

    grids = [
        grid[1:start_pos[1], start_pos[2]:end],
        grid[1:start_pos[1], 1:start_pos[2]],
        grid[start_pos[1]:end, 1:start_pos[2]],
        grid[start_pos[1]:end, start_pos[2]:end]
    ]

    total_length = 0
    for i ∈ axes(grids, 1)
        graph = make_full_graph(grids[i])
        path = the_shortest_hamiltonian_path(graph, graph.nodes['@'])
        # println(path)
        total_length += path
    end
    println("PART 2: ", total_length)
end

function main()
    grid = load_grid("input18.txt")
    
    part1(grid)
    part2!(grid)

    grid = load_grid("input18.txt")
    @time part1(grid)
    @time part2!(grid)
end

main()
