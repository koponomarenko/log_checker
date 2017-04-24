#!/bin/bash

cmd="journalctl --since=yesterday --until=today | grep \"Received message has invalid digest\""
#cmd="journalctl --since=yesterday --until=today | grep \"Logs begin at\""

look_for_log_entries()
{
    for ip in ${host_list[@]}; do
        ping -c 1 -W 1 "$ip" &>/dev/null
        if [ $? -ne 0 ]; then
            echo "host-ip: $ip UNREACHABLE"
            continue
        fi
        ssh-keygen -R $ip &>/dev/null
        host_name=$(sshpass -p "$pass" ssh -q -o StrictHostKeyChecking=no ${login}@${ip} hostname)
        res_file_name="$(date +"%Y-%m-%d--%H-%M-%S")_$host_name"
        echo "IP: $ip, HOSTNAME: $host_name" | tee $res_file_name
        sshpass -p "$pass" ssh -q -o StrictHostKeyChecking=no ${login}@${ip} $cmd >$res_file_name
        if [[ $? -eq 0 ]] && [[ -n "$email" ]]; then
            # notify via email
            echo "send email"
        fi
        [ -s $res_file_name ] || rm $res_file_name
    done
}

while [[ $# -gt 0 ]]; do
case $1 in
    -h|--hostlist)
        eval "host_list=($(< $2))"
        shift
    ;;
    -c|--cmd)
        cmd="$2"
        shift
    ;;
    -l|--login)
        login="$2"
        shift
    ;;
    -p|--pass)
        pass="$2"
        shift
    ;;
    -e|--email)
        email="yes"
    ;;
    *)
        usage
        exit 1
    ;;
esac
shift # past argument or value
done

rc=0
if [[ -z "$host_list" ]]; then
    echo "-h|--hostlist <hostlist>"
    rc=1
fi
if [[ -z "$cmd" ]]; then
    echo "-c|--cmd <command>"
    rc=1
fi
if [[ -z "$login" ]]; then                                                                 
    echo "-l|--login <user_name>"                                                            
    rc=1                                                                               
fi 
if [[ -z "$pass" ]]; then                                                                 
    echo "-p|--pass <password>"                                                            
    rc=1                                                                               
fi

[[ $rc -eq 0 ]] || exit 0

look_for_log_entries
