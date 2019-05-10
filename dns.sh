#!/bin/bash
echo "-----------------------------------------------------------------------"
#Record variable assignment
if [ -z $4 ]
then
record="A"
else
record="$4"
fi
#SOA dig
ns1_SOA=$(dig +short @dns1.namecheaphosting.com $3 SOA | awk '{print $3}')
ns2_SOA=$(dig +short @dns2.namecheaphosting.com $3 SOA | awk '{print $3}')
google_SOA=$(dig +short @8.8.8.8 $3 SOA | awk '{print $3}')
#$4 record dig
ns1=$(dig +short @dns1.namecheaphosting.com $3 $record)
ns2=$(dig +short @dns2.namecheaphosting.com $3 $record)
google=$(dig +short @8.8.8.8 $3 $record)
#Else/if for dig from different servers
if [ "$1" = "s" ]
then
        host="server$2.web-hosting.com"
                server_SOA=$(dig +short @$host $3 SOA | awk '{print $3}')
                server=$(dig +short @$host $3 $record )
elif [ "$1" = "p" ]
then
        host="premium$2.web-hosting.com"
                server_SOA=$(dig +short @$host $3 SOA | awk '{print $3}')
                server=$(dig +short @$host $3 $record)
elif [ "$1" = "b" ]
then
        host="business$2.web-hosting.com"
                server_SOA=$(dig +short @$host $3 SOA | awk '{print $3}')
                server=$(dig +short @$host $3 $record)
else
echo "Incorrect servername. Please double-check the letter used."
echo "You can use the following options:"
echo "s - serverXX.web-hosting.com"
echo "p - premiumXX.web-hosting.com"
echo "b - businessXX.web-hosting.com"
exit
fi

#Check if the SOA same on both cluster NS
if [ "$ns1" != "$ns2" ]
then
echo "The $4 record differs on the cluster"
fi

#Check for child zone misconfiguration
soa2=$( dig +short $3 @dns1.namecheaphosting.com SOA | grep ".registrar-servers.com" )
if [ "$soa2" ]
then
echo -e "\e[31mNOTICE. There seems to be a misconfiguration between our Web Hosting DNS and Basic DNS\e[0m"
echo '--------------------------------------------------------------------------------------'
fi
#Check if  record is present on the server
if [ -z "$server" ]
then
        if [ -z $server_SOA ]
        then
        echo -e "\e[31mThere is NO zone for the $3 on $host\e[0m"
        exit
        else
        echo -e "\e[31mThere is NO $4 record on the $host\e[0m"
        exit
        fi
else
hostname_server=$(host $server | awk '{ print $5 }')
fi
#hostname output
if [ "$record" = "A" ]
then
        if [ -z $google ]
        then
        echo -e "\e[95mNO $record record on Google\e[0m"
        else
        hostname_google=$(host $google | awk '{ print $5 }')
        fi

        if  [ -z $ns1 ]
        then
        echo -e "\e[93mNO $record record on Cluster\e[0m"
        else
        hostname_cluster=$(host $ns1 | awk '{ print $5 }')
        fi
fi
#Check if the record on cluster/google/server are the same

if [ "$ns1" = "$server" ]
then
        if [ "$server" = "$google" ]
        then
        #Record is equal everywhere
        echo "$record record is up to date: $server | $hostname_server"
        else
        #NOT equal on Google, same on cluster/serv
        echo -e "$record record is the same on server/cluster \e[95mNOT Google\e[0m"
        echo -e "\e[32m$record record on server/cluster: $server | $hostname_server\e[0m"
        echo -e "\e[95m$record record on Google side is: $google | $hostname_google\e[0m"
        fi
else
#record differs on server and cluster
echo -e "\e[31m$record record differs on cluster and server\e[0m"
echo "Server : $server | $hostname_server"
echo "Cluster: $ns1 | $hostname_cluster"
fi


#SOA check
if [ "$ns1_SOA" = "$server_SOA" ]
then
        if [ "$server_SOA" = "$google_SOA" ]
        then
        #Record is equal everywhere
        echo "SOA record is up to date: $server_SOA"
        else
        #NOT equal on Google, same on cluster/serv
        echo -e "SOA record is the same on server and cluster \e[95mNOT Google\e[0m"
        echo -e "\e[95mSOA record on Google side is: $google_SOA\e[0m"
        echo -e "\e[32mSOA record on server/cluster: $server_SOA\e[0m"
        fi
else
#record differs on server and cluster
echo -e "\e[31mSOA record differs on cluster and server\e[0m"
echo "Server : $server_SOA"
echo "Cluster: $ns1_SOA"
fi
echo "-----------------------------------------------------------------------"
#echo "ns1 == $ns1"
#echo "server == $server"
#echo "google == $google"
#echo $host
