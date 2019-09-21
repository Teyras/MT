#!/bin/sh

results=$1
input_dep_results=$2
target_dir=$3

echo === Illustration
Rscript stability-illustration.r
cp stability-illustration.tex $target_dir/img/stability/

echo === Dependence on input
Rscript plot-dependence-on-input.r $input_dep_results > /dev/null
#cp dependence-on-input-sds-histogram.png $target_dir/img/stability/
cp dependence-on-input-means.png $target_dir/img/stability/
cp dependence-on-input-sds.png $target_dir/img/stability/

echo === Warmup
Rscript check-warmup.r $results > /dev/null
cp warmup.tex $target_dir/img/stability/

echo === Isolate wall clock time
Rscript time-isolate-vs-bare.r $results > /dev/null
cp iso-wall-err.md $target_dir/tables/stability/
cp iso-cpu-err.md $target_dir/tables/stability/
cp iso-wall-err.tex $target_dir/img/stability/
cp iso-cpu-err.tex $target_dir/img/stability/

echo === Bootstrap CI comparisons
Rscript compare-virt-ci.r $results
cp virt-ci-comparison.tex $target_dir/img/stability/
Rscript compare-isolate-ci.r $results
cp isolate-ci-comparison.tex $target_dir/img/stability/

echo === Paralelization
Rscript plot-paralelization.r $results > /dev/null
cp isolation-comparison.png $target_dir/img/stability/
cp isolation-comparison-taskset.png $target_dir/img/stability/

Rscript plot-means-by-setup-size.r $results > /dev/null
cp means_by_setup_size/bsearch-over-isolations.tex $target_dir/img/stability/

echo === Parallel runs
python check-parallel-runs.py $results > $target_dir/tables/stability/parallel-run-ratios.md

echo === Taskset comparison
Rscript compare-taskset.r $results > /dev/null
cp taskset/taskset-comparison.tex $target_dir/img/stability/
cp taskset/taskset-default-vs-taskset-multi-bare.tex $target_dir/img/stability/
cp taskset/taskset-default-vs-taskset-multi-isolate.tex $target_dir/img/stability/
