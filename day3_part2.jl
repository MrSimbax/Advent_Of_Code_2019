struct Point
    x::Int
    y::Int
end

struct Segment
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
            error("ERROR: bad direction: $direction")
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
        min_intersection_steps = typemax(Int)
        current_steps1 = 0
        current_steps2 = 0
        prev_seg1 = Point(0, 0)
        prev_seg2 = Point(0, 0)
        visited_intersections_steps_1 = Dict{Point,Int}()
        visited_intersections_steps_2 = Dict{Point,Int}()
        center = Point(0, 0)
        for segment1 in segments1
            current_steps2 = 0
            for segment2 in segments2
                intersection = find_intersection(segment1, segment2)
                if intersection != nothing
                    intersections = []
                    if typeof(intersection) == Segment
                        # The intersection is a segment, we must find the closest point on it
                        if intersection.from.y == intersection.to.y
                            y = intersection.from.y
                            intersections = [Point(x, y) for x in intersection.from.x:intersection.to.x]
                        else
                            x = intersection.from.x
                            intersections = [Point(x, y) for y in intersection.from.y:intersection.to.y]
                        end
                    else
                        intersections = [intersection]
                    end

                    for intersection in intersections
                        if metric(center, intersection) == 0
                            continue
                        end

                        steps1 = current_steps1 + metric(prev_seg1, intersection)
                        steps2 = current_steps2 + metric(prev_seg2, intersection)
                        if haskey(visited_intersections_steps_1, intersection)
                            steps1 = visited_intersections_steps_1[intersection]
                        else
                            visited_intersections_steps_1[intersection] = steps1
                        end
                        if haskey(visited_intersections_steps_2, intersection)
                            steps2 = visited_intersections_steps_2[intersection]
                        else
                            visited_intersections_steps_2[intersection] = steps2
                        end

                        # Update minimum
                        intersection_steps = steps1 + steps2
                        if intersection_steps < min_intersection_steps
                            min_intersection = intersection
                            min_intersection_steps = intersection_steps
                        end
                    end
                end

                current_steps2 += metric(segment2.from, segment2.to)
                prev_seg2 = prev_seg2 == segment2.from ? segment2.to : segment2.from
            end
            
            current_steps1 += metric(segment1.from, segment1.to)
            prev_seg1 = prev_seg1 == segment1.from ? segment1.to : segment1.from
        end

        println(min_intersection)
        println(min_intersection_steps)
    end
end

main()
