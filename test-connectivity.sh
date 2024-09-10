function ping_ips() {
    local service_name=$1
    echo -e "\n++++++++ Running @ $nodename ++++++++\n"
    echo "++++++++ Testing $service_name ++++++++"
    ep_list=$(kubectl get endpoints "$service_name" -o jsonpath='{range .subsets[*].addresses[*]}{@.ip}{" "}{@.nodeName}{"\n"}{end}')
    while IFS= read -r line
    do
      ip=$(echo "$line" | cut -f1 -d' ')
      node=$(echo "$line" | cut -f2 -d' ')
      ping -c 1 "$ip" > /dev/null
      if [ $? -ne 0 ]
      then
        echo "ERROR: ********** ping $ip @ $node failed **********"
        exit 1
      fi
      echo "$(date): $ip @ $node - OK"
    done <<< "$ep_list"
}

hostname=$(cat /etc/hostname)
nodename=$(kubectl get pods $hostname -o jsonpath={.spec.nodeName})
nodename="${nodename:-$hostname}"

while true
do
    ping_ips "host-network"
    ping_ips "pod-network"
    sleep 30
done
