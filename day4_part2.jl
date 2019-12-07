function main(from, to)
    count = 0
    for password in from:to
        adjacent = false
        nondecreasing = true
        password_str = string(password)
        for i = 2:length(password_str)
            if password_str[i - 1] > password_str[i]
                nondecreasing = false
                break
            end
            if (!adjacent && password_str[i - 1] == password_str[i] &&
                !((i > 2 && password_str[i - 2] == password_str[i - 1]) ||
                  (i < length(password_str) && password_str[i] == password_str[i + 1])))
                adjacent = true
            end
        end
        if nondecreasing && adjacent
            count += 1
        end
    end
    println(count)
end

main(193651, 649729)

