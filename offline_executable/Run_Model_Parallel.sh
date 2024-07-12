#!/bin/bash
#------------------------------------------------------------------------
#------------------------------------------------------------------------
# Run CLM model in parallel in the context of model parameters
start_time=$(date +%s)
#------------------------------------------------------------------------
#------------------------------------------------------------------------
# Define parameter combinations
p1_vals=(12.5 15.0 10.0)
p2_vals=(2.5 3.0 2.0)
p3_vals=(-2.5 -3.0 -2.0)
p4_vals=(100 150 200)
#------------------------------------------------------------------------
#------------------------------------------------------------------------
# Basic settings
base_out_dir="../output_files"
mkdir -p "$output_dir"
#------------------------------------------------------------------------
#------------------------------------------------------------------------
for p1 in "${p1_vals[@]}"; do
  for p2 in "${p2_vals[@]}"; do
    for p3 in "${p3_vals[@]}"; do
      for p4 in "${p4_vals[@]}"; do
        # Create a unique identifier for this run
        run_id="p1_${p1}_p2_${p2}_p3_${p3}_p4_${p4}"
        
        # Create a directory for this specific run's output
        run_out_dir="${base_out_dir}/${run_id}"
        mkdir -p "$run_out_dir"

        # Prepare input file for this combination
        param_file="nl.US-UMB.${run_id}"
        cat > "$param_file" <<EOF
&clmML_inparm
tower_name    = 'US-UMB'
start_ymd     = 20060701
start_tod     = 0
stop_option   = 'ndays'
stop_n        = 31
clm_start_ymd = 20060101
clm_start_tod = 0
p1 = $p1
p2 = $p2
p3 = $p3
p4 = $p4
out_dir = '${run_out_dir}/'
/
EOF
        # Run the model in background
        ./prgm.exe < "$param_file" &
        rm "$param_file"
      done
    done
  done
done

wait

echo "----All simulations completed----"
#------------------------------------------------------------------------
#------------------------------------------------------------------------
end_time=$(date +%s)
total_run_time=$((end_time - start_time))
echo "Total run time of all simulations: $total_run_time seconds"
#------------------------------------------------------------------------
#------------------------------------------------------------------------
