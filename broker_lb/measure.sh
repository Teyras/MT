#!/bin/sh

SIMULATOR=./build/lb-simulator
ROOT_DIR=$(realpath $(dirname $0))
SETUPS_DIR=$ROOT_DIR/setups
WORKLOADS_DIR=$ROOT_DIR/workloads
LOGS_DIR=$ROOT_DIR/logs

results_file=$ROOT_DIR/results-lb.$(date '+%Y-%m-%d_%H:%M:%S').csv
mkdir -p $LOGS_DIR
rm $LOGS_DIR/*

generate_inputs() {
    pushd $WORKLOADS_DIR/generators/ > /dev/null

    python simple+para.py --count 1000 --avg-delay 30 --simple-duration 300 100 --para-rate 25 --para-duration 600 200 \
                          > $WORKLOADS_DIR/simple+para_small.csv
    python simple+para.py --count 4000 --avg-delay 30 --simple-duration 300 100 --para-rate 25 --para-duration 600 200 \
                          > $WORKLOADS_DIR/simple+para_large.csv

    python two_phase.py --count 1000 --avg-delay 70 --phase-threshold 600 --second-rate 80 --first-duration 300 100 \
                        --second-duration 500 150 > $WORKLOADS_DIR/two_phase_small.csv

    popd > /dev/null
}

arg_sets=$(mktemp)
queue_managers="multi single_fcfs single_lf single_spt_oracle single_edf_oracle oagm_oracle multi_ll_queue_size multi_ll_oracle multi_rand2_queue_size multi_rand2_oracle"
for queue_manager in $queue_managers; do
    workload=simple+para_small
    echo $queue_manager simple+para-small $workload >> $arg_sets
    echo $queue_manager simple+para-large $workload >> $arg_sets

    workload=simple+para_large
    echo $queue_manager simple+para-large $workload >> $arg_sets

    workload=two_phase_small
    echo $queue_manager two-types-small $workload >> $arg_sets
    echo $queue_manager two-types-large $workload >> $arg_sets
done

generate_inputs

cat $arg_sets | parallel --colsep=" " --tagstring={1},{2},{3}, --joblog $LOGS_DIR/jobs.tsv \
    $SIMULATOR {1} $SETUPS_DIR/{2}.yml $WORKLOADS_DIR/{3}.csv \
    "2>" $LOGS_DIR/{1},{2},{3}.log > $results_file

rm $arg_sets

