Simple PE 3.3.2 AWS Demo


To setup a master, use the Red Hat 6 HVM image in amazon (https://aws.amazon.com/marketplace/pp/B00CFQWLS6) - use this for the agent also.

t2.medium or m3.medium should be adequate for testing, but m3.large is suggested for anything long running.

For agents, you can use t2.micros, but be aware their network connectivity is limited.

Ideally you will want to deploy this in a VPC.

Deploy the EC Instance using the master.sh userdata script, you can modify it to use the passwords that you want, or you can use it as is and the console username/password is admin@puppetlabs.com / password

Once that instance has finished its boot script (check /var/log/messages for the last of the puppet agent run), you should be able to log into the web interface at :443 and login with those credentials.

Deploy the EC2 instances you want to use as agents using that el6.agent.sh user data script, modifying it first to use the internal hostname of the EC Instance you deployed for the master.
