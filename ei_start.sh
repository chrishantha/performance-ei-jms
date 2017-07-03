#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_131
if pgrep -f "carbon" > /dev/null; then
    echo "Shutting down EI"
    /mnt/wso2/wso2ei-6.1.0/bin/integrator.sh stop
    sleep 30
fi

log_files=(/mnt/wso2/wso2ei-6.1.0/repository/logs/*)
if [ ${#log_files[@]} -gt 1 ]; then
    # Replacing old logs to avoid disk out of space issues. Removed $(date +"/tmp/ei-logs-%Y-%m-%d-%H-%M-%S")
    log_move_path=$(date +"/tmp/ei-logs-%Y-%m-%d")
    mkdir -p $log_move_path
    echo "Log files exists. Moving to $log_move_path"
    mv /mnt/wso2/wso2ei-6.1.0/repository/logs/* $log_move_path;
fi

echo "Configuring EI for scenario $1"
cp scenarios/$1/StockQuoteProxy.xml /mnt/wso2/wso2ei-6.1.0/repository/deployment/server/synapse-configs/default/proxy-services
cp scenarios/$1/StockQuoteAPI.xml /mnt/wso2/wso2ei-6.1.0/repository/deployment/server/synapse-configs/default/api
cp scenarios/$1/axis2.xml /mnt/wso2/wso2ei-6.1.0/conf/axis2

echo "Starting EI"
/mnt/wso2/wso2ei-6.1.0/bin/integrator.sh start
sleep 120