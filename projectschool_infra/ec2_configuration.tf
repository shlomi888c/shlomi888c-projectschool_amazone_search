resource "aws_launch_configuration" "app" {
  name      = "app1"
  image_id = "ami-0574da719dca65348"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.ec2_ssh.id}"]
  #associate_public_ip_address = true
  key_name =  "consul_key"
  user_data = <<-EOF
#!/bin/bash
echo "jenkins ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
sudo  apt-get update -y
sudo apt-get upgrade -y
sudo  wget https://packages.chef.io/files/stable/chef-workstation/21.10.640/ubuntu/20.04/chef-workstation_21.10.640-1_amd64.deb
sudo  dpkg -i chef-workstation_21.10.640-1_amd64.deb
sudo mkdir -p /etc/chef/cookbooks/flaskapp/recipes
sudo git clone https://github.com/shlomi888c/flask_app_recipe.git
sudo mv /flask_app_recipe/default.rb /etc/chef/cookbooks/flaskapp/recipes
sudo sh -c 'echo "file_cache_path \"/tmp/chef-solo\"" > /etc/chef/solo.rb'
sudo sh -c 'echo "cookbook_path \"/etc/chef/cookbooks\"" >> /etc/chef/solo.rb'
sudo sh -c 'echo "{ \"run_list\": [ \"recipe[flaskapp::default]\" ]}" > /etc/chef/webserver.json'
sudo chef-solo -c /etc/chef/solo.rb -j /etc/chef/webserver.json  --chef-license accept
touch /etc/profile.d/flaskapp.sh
touch /etc/profile.d/flaskapp1.sh
touch /etc/profile.d/flaskapp2.sh
touch /etc/profile.d/flaskapp3.sh
echo export USER=shlomi | sudo tee -a /etc/profile.d/flaskapp.sh
echo export PASSWORD=Shimi431 | sudo tee -a /etc/profile.d/flaskapp1.sh
echo export ip_consul=${data.terraform_remote_state.vpc.outputs.instance_public_ip} | sudo tee -a /etc/profile.d/flaskapp2.sh
echo export hostrds=test.ciignquihkpp.us-east-1.rds.amazonaws.com | sudo tee -a /etc/profile.d/flaskapp3.sh
sudo python3 /home/projectschool/flask_app.py
EOF
}



output "database_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.tutorial_database.address
}

output "alb_dns_name" {
  value = aws_alb.app_alb.dns_name
}