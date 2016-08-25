r53updater
==========

A perl client to check the current IP address of an ethernet interface and update Amazon Route 53 with a change. This would be used if you have your nameserver for your domain at AWS and you have a dynamic IP address.

Dependencies
------------

r53updater.json - a file that contains a JSON hash with elements:

id - your Amazon AWS ID

key - your Amazon AWS secret key

domains - a list of domains to check and change on AWS Route 53

lastIP - placeholder for the last IP value stored, it will be updated

