#!/bin/bash
if [[ -d results ]]; then
    echo "Results directory already exists"
    exit 1
fi

concurrent_users=(10)

ei_host=172.31.9.33

scenario=$1

ei_ssh_host=exp2
activemq_ssh_host=exp3

mkdir -p results/gclogs
cp $0 results

export PATH=$PATH:/mnt/test/apache-jmeter-3.2/bin

run_jmeter() {
    mkdir -p results/$1/$3
    report_location=results/$1/$3
    export JVM_ARGS="-Xms4g -Xmx4g -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:$PWD/results/gclogs/jmeter_gc_$1.log"
    echo "# Running JMeter. Concurrent Users: $1 Duration: $2 JVM Args: $JVM_ARGS"
    jmeter.sh -n -t api-jms-test.jmx -Jhost=$ei_host -Jusers=$1 -Jduration=$2 -l $report_location-all.jtl -e -o $report_location-all
    java -Xms4g -Xmx4g -jar utility-tools-1.0-SNAPSHOT-jar-with-dependencies.jar $report_location-all.jtl $report_location-measurement.jtl 300
    export JVM_ARGS="-Xms4g -Xmx4g"
    jmeter.sh -g $report_location-measurement.jtl -o $report_location-measurement
    ss -s > results/$1/$3/jmeter_ss.txt
    ssh $ei_ssh_host "ss -s" > results/$1/$3/ei_ss.txt
    ssh $activemq_ssh_host "ss -s" > results/$1/$3/activemq_ss.txt
}


run_tests() {
    for u in ${concurrent_users[@]}
    do
        mkdir -p results/$u
        ssh $ei_ssh_host "./ei_start.sh $scenario"
        ssh $activemq_ssh_host "./activemq_start.sh"

        scp $ei_ssh_host:/mnt/wso2/wso2ei-6.1.0/repository/deployment/server/synapse-configs/default/proxy-services/*.xml results
        scp $ei_ssh_host:/mnt/wso2/wso2ei-6.1.0/repository/deployment/server/synapse-configs/default/api/*.xml results
        scp $ei_ssh_host:/mnt/wso2/wso2ei-6.1.0/conf/axis2/axis2.xml results

        run_jmeter $u 30 before
        ssh $activemq_ssh_host "./activemq_start.sh"
        # Sleep to avoid "connection refused" errors in 2nd run.
        sleep 30
        run_jmeter $u 30 after

        scp $ei_ssh_host:/mnt/wso2/wso2ei-6.1.0/repository/logs/gc.log $PWD/results/gclogs/ei_gc_$u.log
        scp $activemq_ssh_host:/home/ubuntu/activemqgc.log $PWD/results/gclogs/activemq_gc_$u.log
        sar -q > results/$u/jmeter_loadavg.txt
        ssh $ei_ssh_host "sar -q" > results/$u/ei_loadavg.txt
        ssh $ei_ssh_host "top -bn 1" > results/$u/ei_top.txt
        ssh $ei_ssh_host "ps u -p \`pgrep -f carbon\`" > results/$u/ei_ps.txt
        ssh $activemq_ssh_host "sar -q" > results/$u/activemq_loadavg.txt
        ssh $activemq_ssh_host "top -bn 1" > results/$u/activemq_top.txt
        ssh $activemq_ssh_host "ps u -p \`pgrep -f activemq\`" > results/$u/activemq_ps.txt
        # Increased due to errors
        sleep 240
    done
}

run_tests

echo "Completed"