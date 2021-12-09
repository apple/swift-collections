#!/bin/zsh

declare -a benchmarks
benchmarks=(
    "init(uniqueKeysWithValues:)"
    "sequential iteration"
    "subscript, successful lookups"
    "subscript, unsuccessful lookups"
    "subscript, noop setter"
    "subscript, set existing"
    "subscript, _modify"
    "subscript, insert"
    "subscript, insert, reserving capacity"
    "subscript, remove existing"
    "subscript, remove missing"
    "defaulted subscript, successful lookups"
    "defaulted subscript, unsuccessful lookups"
    "defaulted subscript, _modify existing"
    "defaulted subscript, _modify missing"
    "updateValue(_:forKey:), existing"
    "updateValue(_:forKey:), insert"
    "random removals (existing keys)"
    "random removals (missing keys)"
)

declare -a classes
classes=(
    "Dictionary<Int, Int>"
    "PersistentDictionary<Int, Int>"
    # "OrderedDictionary<Int, Int>"
)

for benchmark in ${benchmarks[@]}; do
    tasks_file=$(mktemp)

    for class in $classes; do
        echo "$class $benchmark" >> $tasks_file
    done

    rm "results-$benchmark" && rm "chart-$benchmark.png"
    swift run -Xswiftc -Ounchecked -c release swift-collections-benchmark run "results-$benchmark" --tasks-file=$tasks_file --cycles=1
    swift run -Xswiftc -Ounchecked -c release swift-collections-benchmark render "results-$benchmark" "chart-$benchmark.png"
    # open "chart-$benchmark.png"
done
