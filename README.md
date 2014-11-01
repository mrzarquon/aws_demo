Simple PE 3.3.2 AWS Demo


To setup a master, use the Red Hat 6 HVM image in amazon (https://aws.amazon.com/marketplace/pp/B00CFQWLS6) - use this for the agent also.

t2.medium or m3.medium should be adequate for testing, but m3.large is suggested for anything long running.

For agents, you can use t2.micros, but be aware their network connectivity is limited.

Ideally you will want to deploy this in a VPC. 
