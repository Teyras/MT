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

    python multi_type.py --count 1000 --avg-delay 30 --jobs 3,group_common,300,100 1,group_parallel,600,200 \
                         > $WORKLOADS_DIR/simple+para_small.csv
    python multi_type.py --count 4000 --avg-delay 30 --jobs 3,group_common,300,100 1,group_parallel,600,200 \
                         > $WORKLOADS_DIR/simple+para_large.csv

    python multi_type.py --count 1000 --avg-delay 30 --jobs 4,group_common,300,100 1,group_common,10000,4000 \
                         > $WORKLOADS_DIR/long+short_small.csv
    python multi_type.py --count 1000 --avg-delay 30 --jobs 1,group_common,300,100 1,group_common,500,100 \
                         > $WORKLOADS_DIR/medium+short_small.csv

    python multi_type.py --count 1000 --avg-delay 30 --jobs \
                         5,group_common_1,500,100 2,group_common_2,300,100 '3,group_common_1|group_common_2,400,100' \
                         1,group_parallel,600,200 2,group_gpu,1500,500 \
                         > $WORKLOADS_DIR/multi_type_small.csv

    python two_phase.py --count 1000 --avg-delay 70 --phase-threshold 600 --second-rate 80 --first-duration 300 100 \
                        --second-duration 500 150 > $WORKLOADS_DIR/two_phase.csv

    popd > /dev/null
}

arg_sets=$(mktemp)
queue_managers="multi_rr single_fcfs single_lf single_spt_oracle single_edf_oracle oagm_oracle multi_ll_queue_size multi_ll_oracle multi_rand2_queue_size multi_rand2_oracle"
for queue_manager in $queue_managers; do
    workload=simple+para_small
    echo $queue_manager two_types_small $workload >> $arg_sets
    echo $queue_manager two_types_large $workload >> $arg_sets

    workload=simple+para_large
    echo $queue_manager two_types_large $workload >> $arg_sets

    workload=multi_type_small
    echo $queue_manager multiple_types $workload >> $arg_sets

    workload=two_phase
    echo $queue_manager uniform_small $workload >> $arg_sets
    echo $queue_manager uniform_large $workload >> $arg_sets

    workload=long+short_small
    echo $queue_manager uniform_large $workload >> $arg_sets

    workload=medium+short_small
    echo $queue_manager uniform_small $workload >> $arg_sets
done

generate_inputs

cat $arg_sets | parallel --colsep=" " --tagstring={1},{2},{3}, --joblog $LOGS_DIR/jobs.tsv \
    $SIMULATOR {1} $SETUPS_DIR/{2}.yml $WORKLOADS_DIR/{3}.csv \
    "2>" $LOGS_DIR/{1},{2},{3}.log > $results_file

rm $arg_sets

