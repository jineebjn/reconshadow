#!/bin/bash
#Author:Jineeb J N

echo "

██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗
██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║
██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║
██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║
██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝
╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝ 
                               # By red_shadow_11 #                                         "
scriptName="reconShadow"

read -p "Enter the domain : " target
# target="jineebjn.com"
echo "Domain : $target"
# exit

# Sublist3r
# sublist3r -d $domain -o sublist3r_$domain.txt



if [[ $(id -u) != 0 ]]; then
    echo -e "\n[!] Install.sh requires root privileges"
    exit 0
fi

if [ ! -d "$target" ];then
	mkdir $target
fi
if [ ! -d "$target/$scriptName" ];then
	mkdir $target/$scriptName
fi
if [ ! -d '$target/$scriptName/sublist3r' ];then
	mkdir $target/$scriptName/sublist3r
	touch $target/$scriptName/sublist3r/subdomains.txt
fi
if [ ! -d '$tagget/$scriptName/httprobe' ]; then
	mkdir $target/$scriptName/httprobe
fi
if [ ! -d '$target/$scriptName/assetfinder' ];then
	mkdir $target/$scriptName/assetfinder
	touch $target/$scriptName/assetfinder/subdomains1.txt
fi
if [ ! -d '$target/$scriptName/Subdomain_Takeover' ]; then
	mkdir $target/$scriptName/Subdomain_Takeover
fi
if [ ! -d '$target/$scriptName/scans' ]; then
	mkdir $target/$scriptName/scans
fi
if [ ! -d '$target/$scriptName/wayback_urls' ]; then
	mkdir $target/$scriptName/wayback_urls
	mkdir $target/$scriptName/wayback_urls/params
	touch $target/$scriptName/wayback_urls/params/params.txt
	mkdir $target/$scriptName/wayback_urls/extensions
fi
if [ ! -d '$target/$scriptName/amass' ]; then
	mkdir $target/$scriptName/amass
	touch $target/$scriptName/amass/subdomains2.txt
fi
if [ ! -d '$target/$scriptName/knockpy' ]; then
	mkdir $target/$scriptName/knockpy
	touch $target/$scriptName/knockpy/subdomains3.txt
fi
if [ ! -f "$target/$scriptName/httprobe/alivee.txt" ];then
	touch $target/$scriptName/httprobe/alivee.txt
fi

# if [ ! -f "$target/$scriptName/dnsrecon/dnsrecon_output.xml" ];then
# 	touch $target/$scriptName/dnsrecon/dnsrecon_output.xml
# fi

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
echo
echo ${yellow}"Welcome to the ReconShadow Script-An Excellent Automation Script For Bug Bounty/Pentesting"${yellow}
echo
echo ${yellow}"[+++]Recon is in Progress Take A Cofee or Tea ;)[+++]"${yellow}
echo

echo
echo ${red}"[+++] Gatherings subdomains with assetfinder and Sublist3r...[+++]"${red}
assetfinder $target >> $target/$scriptName/assetfinder/subdomains1.txt
cat $target/$scriptName/assetfinder/subdomains1.txt | grep $target >> $target/$scriptName/Subdomain_final.txt
echo

sublist3r -d $target -v -t 100 -o $target/$scriptName/sublist3r/subdomains.txt
cat $target/$scriptName/sublist3r/subdomains.txt | grep $target >> $target/$scriptName/Subdomain_final.txt
echo

echo
echo ${red}"[+++] Duplex checking for subdomains with amass...[+++]"${red}
amass enum -d $target -o $target/$scriptName/amass/subdomains2.txt
cat $target/$scriptName/amass/subdomains2.txt | grep $target >> $target/$scriptName/Subdomain_final.txt
echo

echo
echo ${red}"[+++] Enumerating subdomains on a target domain through dictionary attack...[+++]"${red}
knockpy $target >> $target/$scriptName/knockpy/subdomains3.txt 
awk '/$target/ {print}' $target/$scriptName/knockpy/subdomains3.txt | cut -d " " -f 9 | sed -E 's/.*\b([a-zA-Z0-9.-]+)\b.*/\1/' >> $target/$scriptName/Subdomain_final.txt
sort -u $target/$scriptName/Subdomain_final.txt -o $target/$scriptName/Subdomain_final.txt
echo

echo
echo ${red}"[+++] Searching for alive domains using Httprobe...[+++]"${red}
cat $target/$scriptName/Subdomain_final.txt | sort -u | httprobe | sed -E 's/^\s*.*:\/\///g' | sort -u >> $target/$scriptName/httprobe/alivee.txt
echo

echo
echo ${red}"[+++] Investigating for feasible subdomain takeover...[+++]"${red}
if [ ! -f "$target/$scriptName/Subdomain_Takeover/Subdomain_Takeover.txt" ];then
	touch $target/$scriptName/Subdomain_Takeover/Subdomain_Takeover.txt
fi
subjack -w $target/$scriptName/Subdomain_final.txt -t 70 -timeout 25 -ssl -c /root/go/src/github.com/haccer/subjack/fingerprints.json -v 3 -o $target/$scriptName/Subdomain_Takeover/Subdomain_Takeover.txt
echo

echo
echo ${red}"[+++] Scanning for open ports using nmap...[+++]"${red}
nmap -iL $target/$scriptName/httprobe/alivee.txt -T4 -oA $target/$scriptName/scans/scanned.txt
echo

echo
echo ${red}"[+++] Pulling and Assembling all possible params found in wayback_url data...[+++]"${red}
if [ ! -f "$target/$scriptName/wayback_urls/wayback_output.txt" ];then
	touch $target/$scriptName/wayback_urls/wayback_output.txt
fi
cat $target/$scriptName/Subdomain_final.txt | waybackurls >> $target/$scriptName/wayback_urls/wayback_output.txt
sort -u $target/$scriptName/wayback_urls/wayback_output.txt
cat $target/$scriptName/wayback_urls/wayback_output.txt | grep '?*=' | cut -d '=' -f 1 | sort -u >> $target/$scriptName/wayback_urls/params/params.txt
for i in $(cat $target/$scriptName/wayback_urls/params/params.txt);do echo $i'=';done
echo

echo
echo ${red}"[+++] Pulling and compiling json/js/php/aspx/ files from wayback output...[+++]"${red}
for i in $(cat $target/$scriptName/wayback_urls/wayback_output.txt);do
	ext="${i##*.}"
	if [[ "ext"=="php" ]];then
		echo $i >> $target/$scriptName/wayback_urls/extensions/php1.txt
		sort -u $target/$scriptName/wayback_urls/extensions/php1.txt >> $target/$scriptName/wayback_urls/extensions/php.txt
		rm $target/$scriptName/wayback_urls/extensions/php1.txt
	fi
	if [[ "ext"=="js" ]];then
		echo $i >> $target/$scriptName/wayback_urls/extensions/js1.txt
		sort -u $target/$scriptName/wayback_urls/extensions/js1.txt >> $target/$scriptName/wayback_urls/extensions/js.txt
		rm $target/$scriptName/wayback_urls/extensions/js1.txt
	fi
	if [[ "ext"=="html" ]];then
		echo $i >> $target/$scriptName/wayback_urls/extensions/html1.txt
		sort -u $target/$scriptName/wayback_urls/extensions/html1.txt >> $target/$scriptName/wayback_urls/extensions/html.txt
		rm $target/$scriptName/wayback_urls/extensions/html1.txt
	fi
	if [[ "ext"=="json" ]];then
		echo $i >> $target/$scriptName/wayback_urls/extensions/json1.txt
		sort -u $target/$scriptName/wayback_urls/extensions/json1.txt >> $target/$scriptName/wayback_urls/extensions/json.txt
		rm $target/$scriptName/wayback_urls/extensions/json1.txt
	fi
	if [[ "ext"=="aspx" ]];then
		echo $i >> $target/$scriptName/wayback_urls/extensions/aspx1.txt
		sort -u $target/$scriptName/wayback_urls/extensions/aspx1.txt >> $target/$scriptName/wayback_urls/extensions/aspx.txt
		rm $target/$scriptName/wayback_urls/extensions/aspx1.txt
	fi
done
sort -u $target/$scriptName/wayback_urls/wayback_output.txt -o $target/$scriptName/wayback_urls/wayback_output.txt


# DNSRecon
echo
dnsrecon -d $target -XML $target/$scriptName/dnsrecon/dnsrecon_output.xml
echo


echo
echo ${yellow}"[+++]Recon Completed ;)[+++]"${yellow}
echo
