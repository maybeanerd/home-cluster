## generate ssh keys 
ssh-keygen -t ed25519 -b 256 -C "sebastian@diluz.io"

use name cluster_rsa

## copy keys to nodes
cat ~/.ssh/cluster_rsa.pub | ssh USER@HOST "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys

ensure that in /etc/ssh/sshd_config , PubkeyAuthentication is set to yes

if changes were necessay, restart service sudo systemctl restart sshd