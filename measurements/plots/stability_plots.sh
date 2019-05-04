#!/bin/sh

results=$1
input_dep_results=$2
target_dir=$3

echo === Dependence on input
Rscript plot-dependence-on-input.r $input_dep_results > /dev/null
#cp dependence-on-input-sds-histogram.png $target_dir/img/stability/
cp dependence-on-input-means.png $target_dir/img/stability/
cp dependence-on-input-sds.png $target_dir/img/stability/

echo === Warmup
Rscript check-warmup.r $results > /dev/null
cp warmup-bsearch.png $target_dir/img/stability/

echo === Isolate wall clock time
Rscript time-isolate-vs-bare.r $results > /dev/null
cp iso-wall-err.md $target_dir/tables/stability/
cp iso-cpu-err.md $target_dir/tables/stability/

echo === Bootstrap means
Rscript compare-bootstrap-means.r $results > $target_dir/tables/stability/mean-ci-comparison.md
Rscript compare-bootstrap-sd.r $results > $target_dir/tables/stability/sd-ci-comparison.md

echo === Paralelization
Rscript plot-paralelization.r $results > /dev/null
cp isolation-comparison.png $target_dir/img/stability/
cp isolation-comparison-taskset.png $target_dir/img/stability/

echo === Parallel runs
python check-parallel-runs.py $results > $target_dir/tables/stability/parallel-run-ratios.md

echo === Taskset comparison
Rscript compare-taskset.r $results > /dev/null
cp taskset/taskset-comparison.png $target_dir/img/stability/
