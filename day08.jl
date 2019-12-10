new_layer(height, width) = fill(0, height, width)

function load_image(inputfile, height, width)
    open(inputfile, "r") do inputfile
        image = [new_layer(height, width)]
        layer_id = 1
        i = 1
        j = 1
        for c in strip(read(inputfile, String))
            if j > width
                i += 1
                if i > height
                    push!(image, new_layer(height, width))
                    layer_id += 1
                    i = 1
                end
                j = 1
            end
            image[layer_id][i,j] = c - '0'
            j += 1
        end
        image
    end
end

function main(height, width)
    image = load_image("input08.txt", height, width)
    
    # Part 1
    layer_id = argmin([count(px->px == 0, layer) for layer in image])
    part1 = count(px->px == 1, image[layer_id]) * count(px->px == 2, image[layer_id])
    println("PART 1: $(part1)")

    # Part 2
    println("PART 2: ")
    for i in 1:height
        for j in 1:width
            for layer in image
                color = layer[i,j]
                if color != 2
                    if color == 1
                        print('█')
                    else
                        print(' ')
                    end
                    break
                end
            end
        end
        println()
    end
end

main(6, 25)
