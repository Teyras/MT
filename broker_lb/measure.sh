#!/bin/sh

SIMULATOR=./build/lb-simulator
ROOT_DIR=$(realpath $(dirname $0))
SETUPS_DIR=$ROOT_DIR/setups
WORKLOADS_DIR=$ROOT_DIR/workloads
LOGS_DIR=$ROOT_DIR/logs

results_file=$ROOT_DIR/results-lb.$(date '+%Y-%m-%d_%H:%M:%S').csv
mkdir -p $LOGS_DIR

pushd $WORKLOADS_DIR/generators/
python simple+para.py --count 1000 --avg-delay 30 --simple-duration 300 100 --para-rate 25 --para-duration 600 200 \
                      > $WORKLOADS_DIR/simple+para_small.csv
python simple+para.py --count 4000 --avg-delay 30 --simple-duration 300 100 --para-rate 25 --para-duration 600 200 \
                      > $WORKLOADS_DIR/simple+para_large.csv

python two_phase.py --count 1000 --avg-delay 30 --phase-threshold 600 --second-rate 80 --first-duration 300 100 \
                    --second-duration 500 150 > $WORKLOADS_DIR/two_phase_small.csv
python two_phase.py --count 4000 --avg-delay 30 --phase-threshold 2400 --second-rate 80 --first-duration 300 100 \
                    --second-duration 500 150 > $WORKLOADS_DIR/two_phase_large.csv
popd

run_simulator() {
    setup_arg=$1
    workload_arg=$2

    for queue_manager in multi; do
        $SIMULATOR $queue_manager $SETUPS_DIR/$setup_arg.yml $WORKLOADS_DIR/$workload_arg.csv \
            2> $LOGS_DIR/$queue_manager,$setup_arg,$workload_arg.log |
            sed "s/^/$queue_manager,$setup_arg,$workload_arg,/"
    done
}

for variant in small large; do
    workload=simple+para_$variant
    run_simulator simple+para_small $workload >> $results_file
    run_simulator simple+para_large $workload >> $results_file
done

for variant in small large; do
    workload=two_types_$variant
    run_simulator two_types_small $workload >> $results_file
    run_simulator two_types_large $workload >> $results_file
done
