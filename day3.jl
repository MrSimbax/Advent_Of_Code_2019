mutable struct Point
    x::Int
    y::Int
end

mutable struct Segment
    from::Point
    to::Point
end

function metric(A::Point, B::Point)
    abs(A.x - B.x) + abs(A.y - B.y)
end

# from point is always on the left/down
function get_segments_from_moves(moves)
    current_pos = next_pos = Point(0, 0)
    segments::Array{Segment,1} = []
    for move in moves
        direction = move[1]
        distance = move[2]
        if direction == 'U'
            next_pos = Point(current_pos.x, current_pos.y + distance)
            push!(segments, Segment(current_pos, next_pos))
        elseif direction == 'D'
            next_pos = Point(current_pos.x, current_pos.y - distance)
            push!(segments, Segment(next_pos, current_pos))
        elseif direction == 'L'
            next_pos = Point(current_pos.x - distance, current_pos.y)
            push!(segments, Segment(next_pos, current_pos))
        elseif direction == 'R'
            next_pos = Point(current_pos.x + distance, current_pos.y)
            push!(segments, Segment(current_pos, next_pos))
        else
            println("ERROR: bad direction: $direction")
            exit(1)
        end
        current_pos = next_pos
    end
    return segments
end

function is_in_segment(x::Int, from::Int, to::Int)
    from <= x <= to
end

function find_intersection(segment1::Segment, segment2::Segment)
    # 4 cases
    is_segment1_horizontal = segment1.from.y == segment1.to.y
    is_segment2_horizontal = segment2.from.y == segment2.to.y
    # vertical/horizontal
    if !is_segment1_horizontal && is_segment2_horizontal
        x = segment1.from.x
        y = segment2.from.y
        if is_in_segment(x, segment2.from.x, segment2.to.x) && is_in_segment(y, segment1.from.y, segment1.to.y)
            return Point(x, y)
        else
            return nothing
        end
    # horizontal/vertical
    elseif is_segment1_horizontal && !is_segment2_horizontal
        x = segment2.from.x
        y = segment1.from.y
        if is_in_segment(x, segment1.from.x, segment1.to.x) && is_in_segment(y, segment2.from.y, segment2.to.y)
            return Point(x, y)
        else
            return nothing
        end
    # horizontal/horizontal
    elseif is_segment1_horizontal && is_segment2_horizontal
        if segment1.from.y != segment2.from.y
            return nothing
        end
        y = segment1.from.y
        left = max(segment1.from.x, segment2.from.x)
        right = min(segment1.to.x, segment2.to.x)
        if left > right
            return nothing
        else
            return Segment(Point(left, y), Point(right, y))
        end
    # vertical/vertical
    else
        if segment1.from.x != segment2.from.x
            return nothing
        end
        x = segment1.from.x
        left = max(segment1.from.y, segment2.from.y)
        right = min(segment1.to.y, segment2.to.y)
        if left > right
            return nothing
        else
            return Segment(Point(x, left), Point(x, right))
        end
    end
end

function main()
    open("input3.txt", "r") do inputfile
        wire1 = split(strip(readline(inputfile)), ",")
        wire2 = split(strip(readline(inputfile)), ",")
        
        wire1 = [(move[1], parse(Int, move[2:end])) for move in wire1]
        wire2 = [(move[1], parse(Int, move[2:end])) for move in wire2]

        segments1 = get_segments_from_moves(wire1)
        segments2 = get_segments_from_moves(wire2)

        min_intersection = nothing
        min_intersection_distance = typemax(Int)
        center = Point(0, 0)
        for segment1 in segments1
            for segment2 in segments2
                intersection = find_intersection(segment1, segment2)
                if intersection === nothing
                    continue
                elseif typeof(intersection) == Segment
                    # The intersection is a segment, we must find the closest point on it
                    is_horizontal = intersection.from.y == intersection.to.y
                    if !is_horizontal
                        x = intersection.from.x
                        if is_in_segment(center.y, intersection.from.y, intersection.to.y)
                            intersection = Point(x, center.y)
                        elseif center.y > intersection.from.y 
                            intersection = Point(x, intersection.from.y)
                        else
                            intersection = Point(x, intersection.to.y)
                        end
                    else
                        y = intersection.from.y
                        if is_in_segment(center.x, intersection.from.x, intersection.to.x)
                            intersection = Point(center.x, y)
                        elseif center.x < intersection.from.x
                            intersection = Point(intersection.from.x, y)
                        else
                            intersection = Point(intersection.to.x, y)
                        end
                    end
                end

                # Update minimum
                intersection_distance = metric(center, intersection)
                if intersection_distance < min_intersection_distance && intersection_distance > 0
                    min_intersection = intersection
                    min_intersection_distance = intersection_distance
                end
            end
        end

        println(min_intersection)
        println(min_intersection_distance)
    end
end

main()