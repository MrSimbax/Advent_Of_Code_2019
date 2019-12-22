
function load_data(filename)
    open(filename, "r") do file
        data = split(strip(read(file, String)), '\n')
        data = map(s->match(r"^([a-z\s]+)(?:\s(-?\d+))?$", s).captures, data)
        map(i->[i[1],i[2] != nothing ? parse(Int, i[2]) : nothing], data)
    end
end

function shuffle_cards(shuffling_instructions, l = 10007, repeats = 1)
    cards = collect(0:(l - 1))
    for r ∈ 1:repeats
        for instruction ∈ shuffling_instructions
            name = instruction[1]
            param = instruction[2]
            if name == "deal into new stack"
                reverse!(cards)
            elseif name == "cut"
                N = param
                if N > 0
                    @views cards = [cards[N + 1:end]; cards[1:N]]
                else
                    N *= -1
                    @views cards = [cards[l - N + 1:end]; cards[1:l - N]]
                end
            elseif name == "deal with increment"
                N = param
                tmp = fill(-1, l)
                j = 1
                for i ∈ 1:l
                    tmp[j] = cards[i]
                    j += N
                    if j > l
                        j -= l
                    end
                end
                cards = tmp
            else
                error("Bad instruction: $instruction")
            end
        end
    end
    return cards
end

function follow_shuffle_cards(shuffling_instructions, card, l = 10007, repeats = 1)
    for r ∈ 1:repeats
        for instruction ∈ shuffling_instructions
            name = instruction[1]
            param = instruction[2]
            if name == "deal into new stack"
                card = l - card - 1
            elseif name == "cut"
                N = param
                card = mod(card - N, l)
            elseif name == "deal with increment"
                N = param
                card = mod(card * N, l)
            else
                error("Bad instruction: $instruction")
            end
        end
    end
    return card
end

"""
Time to recall some stuff from all those discrete math/algebra classes.

Each operation is of the form f(x) = (ax+b) mod l
f(x) = y means a card at position x will end up at position y
f^-1(y) = x means a card at position y was at position x
Suppose we have n instructions in one shuffle. The final position of card x is then at
(f_n o f_(n-1) o ... o f_1)(x) = y
Hence, the card at position y is
(f_n o f_(n-1) o ... o f_1)^-1(y) = (f^-1_1 o f^-1_2 o ... o f^-1_n)(y) = x

We end up with a function f(x) = ax+b
Applying it k times we get
f^(k)(x) = a^k x + (a^k - 1) / (a - 1) * b

All those operations are in a finite modulo field Zn.
"""
function part2(shuffling_instructions, pos, l = 10007, repeats = 1)
    # Find the composition of inverses first
    f = (BigInt(1), BigInt(0)) # f = (a, b) = id
    for instruction ∈ reverse(shuffling_instructions)
        name = instruction[1]
        param = instruction[2]
        if name == "deal into new stack"
            f = (mod(-f[1], l), mod(-f[2] - 1 + l, l))
        elseif name == "cut"
            N = mod(BigInt(param), l)
            f = (mod(f[1], l), mod(f[2] + N, l))
        elseif name == "deal with increment"
            N = mod(BigInt(param), l)
            N = invmod(N, l)
            f = (mod(N * f[1], l), mod(N * f[2], l))
        else
            error("Bad instruction: $instruction")
        end
    end

    # Apply it k times
    ak = powermod(f[1], repeats, l)
    geo = if f[1] != 1 (ak - 1) * invmod(f[1] - 1, l) else repeats end
    return mod(ak * pos + geo * f[2], l)
end

function main()
    shuffling_instructions = load_data("input22.txt")
    println("PART 1: ", follow_shuffle_cards(shuffling_instructions, 2019, 10007))
    println("PART 2: ", part2(shuffling_instructions, 2020, 119315717514047, 101741582076661))
end

main()
