# A very rough script to run batches of experiments. Missing checks and command line parametrization

trap ctrlc SIGINT
ctrlc_sent=0

function ctrlc()
{
  let ctrlc_sent=1
}

test_dir=/tmp/rosbag2_test/$(date +%Y%m%d_%H%M%S)
mkdir -p ${test_dir}
echo "${test_dir} created"
db_path=${test_dir}/bag
rm -fr ${db_path}
summary_file=${test_dir}/results.csv

freq=100; #Hz

for cache in 0 1000000 10000000 100000000
do
  for sz in 1000 10000 100000 1000000
  do
    for inst in 1 10 100 1000
    do
      let total=$inst*$sz
      if [[ $total -ne 1000000 ]]; then
        #echo "skipping the case of ${inst} instances and size ${sz}"
        continue
      fi
      echo "processing case of ${inst} instances and size ${sz} with cache ${cache}"
      for try in 1 2 3 4 5
      do
        outdir=${test_dir}/size${sz}_inst${inst}_cache${cache}
        mkdir -p ${outdir}
        outfile=${outdir}/${try}.log
        echo "Results will be written to file: ${outfile}"
        ros2 run rosbag2_performance_writer_benchmarking writer_benchmark --ros-args \
          -p frequency:=${freq} \
          -p size:=${sz} \
          -p instances:=${inst} \
          -p max_cache_size:=${cache} \
          -p db_folder:=${db_path} \
          -p results_file:=${summary_file} \
          --ros-args -r __node:=rosbag2_performance_writer_benchmarking_node_batch \
          2> ${outfile}
        rm -fr ${db_path}
        if [[ $ctrlc_sent -eq 1 ]]; then
          echo -e "\e[31mQuitting prematurely due to Ctrl-C - some results aren't saved and some won't be reliable\e[0m]"
          exit
        fi
      done
    done
  done
done
