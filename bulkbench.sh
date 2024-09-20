#!/bin/bash

# Parse command line arguments
while getopts "d:n:t:" opt; do
    case $opt in
        d) site_url=$OPTARG;;
        n) num_runs=$OPTARG;;
        t) k6_test=$OPTARG;;
        \?) echo "Invalid option -$OPTARG" >&2;;
    esac
done

# Check if required parameters are provided
if [[ -z $site_url || -z $num_runs || -z $k6_test ]]; then
    echo "Missing required parameters. Usage: $0 -d <site_url> -n <num_runs> -t <k6_testfile>"
    exit 1
fi

# check if k6 is installed
if ! command -v k6 &> /dev/null
then
    echo "k6 could not be found. Please install k6 before running this script."
    exit 1
fi

# check if k6 test file exists
if [ ! -f $k6_test ]; then
    echo "The specified k6 test file does not exist."
    exit 1
fi

# strip http:// or https:// from site_url 
domain=$(echo $site_url | sed 's|http[s]*://||')

results_folder="results-$k6_test-$domain"


mkdir -p $results_folder

# Loop through the specified number of runs
for ((i=1; i<=$num_runs; i++))
do
    # Enter the type for the run 
    read -p "Enter the type you are testing for run $i : " run_type
    # Run the K6 benchmark and export the summary to a JSON file
    k6 run $k6_test --vus=10 --duration=2m --env SITE_URL="$site_url" --summary-export="$results_folder/$run_type-$k6_test-$domain-10vus.json"
    sleep 30

    k6 run $k6_test --vus=25 --duration=2m --env SITE_URL="$site_url" --summary-export="$results_folder/$run_type-$k6_test-$domain-25vus.json"
    sleep 30

    k6 run $k6_test --vus=50 --duration=2m --env SITE_URL="$site_url" --summary-export="$results_folder/$run_type-$k6_test-$domain-50vus.json"
    sleep 30

    # Convert the JSON file to a CSV file
    /bin/bash bin/generate-csv.sh "$results_folder/$run_type-$k6_test-$domain-10vus.json" > "$results_folder/results_$domain/$run_type-$k6_test-$domain-10vus.csv"
    /bin/bash bin/generate-csv.sh "$results_folder/$run_type-$k6_test-$domain-25vus.json" > "$results_folder/results_$domain/$run_type-$k6_test-$domain-25vus.csv"
    /bin/bash bin/generate-csv.sh "$results_folder/$run_type-$k6_test-$domain-50vus.json" > "$results_folder/results_$domain/$run_type-$k6_test-$domain-50vus.csv"
    # Output confirmation message
    echo "Run $i complete!"

    # Sleep for 30 seconds before running the next test
    sleep 30
done

# Output final message
echo "All runs complete!"
