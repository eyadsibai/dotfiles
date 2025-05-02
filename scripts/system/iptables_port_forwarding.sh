sudo iptables -t nat -I PREROUTING -p tcp --dport 2222 -j REDIRECT --to-ports 22
sudo iptables -t nat -I OUTPUT -p tcp -o lo --dport 2222 -j REDIRECT --to-ports 22