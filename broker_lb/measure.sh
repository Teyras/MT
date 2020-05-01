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

    job_common_short=group_common_1,500,200 # Short C program
    job_common_medium=group_common_1,2000,500 # A typical C/node/Python program
    job_common_long=group_common_1,10000,4000 # Long Mono or Java program
    job_parallel=group_parallel,8000,2000 # Long parallel evaluation
    job_common_group_2=group_common_2,500,200
    job_common_both_groups='group_common_1|group_common_2,500,200'
    job_gpu=group_gpu,1000000,120000

    python multi_type.py --count 1000 --avg-delay 100 --jobs 3,$job_common_medium 1,$job_parallel \
                         > $WORKLOADS_DIR/simple+para_small.csv
    python multi_type.py --count 4000 --avg-delay 100 --jobs 3,$job_common_medium 1,$job_parallel \
                         > $WORKLOADS_DIR/simple+para_large.csv

    python multi_type.py --count 1000 --avg-delay 100 --jobs 4,$job_common_short 1,$job_common_long \
                         > $WORKLOADS_DIR/long+short.csv
    python multi_type.py --count 1000 --avg-delay 100 --jobs 1,$job_common_short 1,$job_common_medium \
                         > $WORKLOADS_DIR/medium+short.csv

    python multi_type.py --count 1000 --avg-delay 100 --jobs \
                         35,$job_common_medium 30,$job_common_group_2 30,$job_common_both_groups \
                         4,$job_parallel 1,$job_gpu \
                         > $WORKLOADS_DIR/multi_type.csv

    python two_phase.py --count 2000 --avg-delay 550 --phase-threshold 1000 --second-rate 80 \
                        --first-job 0,$job_common_short \
                        --second-job 0,$job_common_long \
                        > $WORKLOADS_DIR/two_phase_small.csv

    python two_phase.py --count 2000 --avg-delay 45 --phase-threshold 1000 --second-rate 80 \
                        --first-job 0,$job_common_short \
                        --second-job 0,$job_common_long \
                        > $WORKLOADS_DIR/two_phase_large.csv

    popd > /dev/null
}

arg_sets=$(mktemp)
queue_managers="multi_rr single_fcfs single_lf single_spt_oracle single_spt_imprecise single_edf_oracle \
                single_edf_imprecise oagm_oracle oagm_imprecise multi_ll_queue_size multi_ll_oracle multi_ll_imprecise \
                multi_rand2_queue_size multi_rand2_oracle multi_rand2_imprecise"
for queue_manager in $queue_managers; do
    workload=simple+para_small
    echo $queue_manager two_types_small $workload >> $arg_sets
    # echo $queue_manager two_types_large $workload >> $arg_sets

    workload=simple+para_large
    echo $queue_manager two_types_large $workload >> $arg_sets

    workload=multi_type
    echo $queue_manager multiple_types $workload >> $arg_sets

    echo $queue_manager uniform_small two_phase_small >> $arg_sets

    echo $queue_manager uniform_large two_phase_large >> $arg_sets

    workload=long+short
    echo $queue_manager uniform_large $workload >> $arg_sets

    workload=medium+short
    echo $queue_manager uniform_small $workload >> $arg_sets
done

generate_inputs

cat $arg_sets | parallel --colsep=" " --tagstring={1},{2},{3}, --joblog $LOGS_DIR/jobs.tsv \
    $SIMULATOR {1} $SETUPS_DIR/{2}.yml $WORKLOADS_DIR/{3}.csv \
    "2>" $LOGS_DIR/{1},{2},{3}.log > $results_file

rm $arg_sets

