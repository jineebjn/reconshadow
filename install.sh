#!/usr/bin/env bash
#Author:Jineeb J N

echo -e '
██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗
██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║
██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║
██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║
██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝
╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝ 
                        # By red_shadow_11 #                                           '
echo
if [[ $(id -u) != 0 ]]; then
    echo -e "\n[!] Install.sh requires root privileges"
    exit 0
fi
echo

apt-get update
apt-get install golang -y
apt-get install zip -y
apt-get install python3-pip
apt-get install nmap
apt-get install dnsrecon
apt-get install httprobe
apt-get install nmap
apt-get install subjack
apt-get install assetfinder
apt-get install amass
apt-get install sublist3r
apt-get install dnsrecon
echo


if [ ! -e /root/go/bin/.waybackurls ];then
	go install github.com/tomnomnom/waybackurls@latest
	ln -sfv /root/go/bin/./waybackurls /usr/bin/waybackurls
else
	echo "Waybackurl is already installed"
fi

if [ ! -e /usr/bin/knockpy ];then
	cd /opt/tools
	git clone https://github.com/guelfoweb/knock.git
	cd knock
        pip3 install -r requirements.txt
	python3 setup.py install
else
	echo "Knockpy is already Installed"
fi

# if [ ! -e /usr/bin/sublist3r ];then
# 	cd /opt
# 	mkdir tools
# 	cd tools
# 	git clone https://github.com/aboul3la/Sublist3r.git
# 	cd Sublist3r
# 	pip3 install -r requirements.txt
# 	cd ../
# 	update-alternatives --install /usr/bin/python python /usr/bin/python3 1
# 	ln -sfv /opt/tools/Sublist3r/sublist3r.py /usr/bin/sublist3r
# else
# 	echo "Sublist3r is already Installed"
# fi


