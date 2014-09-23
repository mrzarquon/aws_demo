AWS Demo For Puppetconf 2014

Puppet Master:
https://ec2-54-68-175-82.us-west-2.compute.amazonaws.com
admin@puppetlabs.com/puppetlabs

Splunk Server:
http://ec2-54-69-81-197.us-west-2.compute.amazonaws.com:8000
admin/puppetlabs

(if you apply the aws\_hosts.pp these servers will be at awsmaster.puppetlabs.demo and awssplunk.puppetlabs.demo)

EC2 Instances:
https://console.aws.amazon.com/ec2/v2/home?region=us-west-2#Instances:sort=launchTime;search=barker

Clone any of the m3.medium (right click, 'launch more like this')

User Data script (example: https://github.com/mrzarquon/mrzarquon-certsigner/blob/master/files/el6.aws.bash)

Tags: puppet\_classes = 'profile::splunk::forwarder' and you can add 'profile::app::jenkins' to show that being provisioned.

"This is a demonstration of showing how to use policy based autosigner and extension attributes to allow public/private clouds to simplify and speed up the deployment of nodes.

The extension attributes (show userdata script) allows us to embed extra data in the SSL certificate used by the agent to identify itself. This allows us to extend the information provided to the master about the agent to be more than just the certificate name. This data is now also available to us using the trusted hash (aka secure facts) that can't be changed once the certificate has been changed.

In the User Data Script you can see how we are both embedding the instance-id in the certicate and using that to set the certificate name, once that has been done (post puppet package installation), we start the agent. A new certificate is generated, it gets the data embedded in it, and then it submits a CSR to the master.

(show https://github.com/mrzarquon/mrzarquon-certsigner/blob/master/files/autosign\_classify.rb) once the certificate signing request is sent to the master, it can now be processed by this external policy script, which connects to AWS and verifies that the instance-id is one belonging to the right credentials, signs the certificate, and then uses that same connection to determine the classification data to use for the first puppet run.

So what do we have?

We can now request a new server from a cloud service, in this case AWS, and we don't have to notify our master or sign a certificate, the signing and classification are happening on demand.

At the end you can show servers that have been deployed, show their uptime, their first run, and how within 3 minutes of uptime (fact submission, etc) they have reports back into the Puppet, configured with mcollective for live management, and splunk collecting their logs."
