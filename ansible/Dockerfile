FROM willhallonline/ansible:latest

# Install required collections and roles
RUN ansible-galaxy collection install -U community.general community.docker
RUN ansible-galaxy role install -p /root/.ansible/roles geerlingguy.docker
