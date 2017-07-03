#!/bin/bash
scenarios=(01 02 03 04 05)

run_scenarios() {
    for n in ${scenarios[@]}
    do
        $PWD/run_all.sh $n > scenario_$n.log 2>&1
        mv scenario_$n.log results
        mv results results_scenario_$n
        echo "Completed scenario $n"
    done
}

run_scenarios

echo "Completed all scnearios"
