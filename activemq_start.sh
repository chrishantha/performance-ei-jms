#!/bin/bash
if pgrep -f "activemq" > /dev/null; then
    echo "Shutting down ActiveMQ"
    /mnt/activemq/apache-activemq-5.14.5/bin/activemq stop
    sleep 2
fi

if [[ -f /home/ubuntu/activemqgc.log ]]; then
    log_move_path=$(date +"/tmp/activemqgc-%Y-%m-%d-%H-%M-%S.log")
    echo "GC Log exists. Moving to $log_move_path"
    mv /home/ubuntu/activemqgc.log $log_move_path
fi

echo "Starting ActiveMQ"
/mnt/activemq/apache-activemq-5.14.5/bin/activemq start
sleep 2
echo "ActiveMQ Stats"
/mnt/activemq/apache-activemq-5.14.5/bin/activemq dstat
echo "Purging Queue and measuring time"
time /mnt/activemq/apache-activemq-5.14.5/bin/activemq purge SimpleStockQuoteService
echo "Restart ActiveMQ after purging"
/mnt/activemq/apache-activemq-5.14.5/bin/activemq restart