r53updater
==========

A perl client to check the current IP address and update Amazon Route 53 with a change

Dependencies
------------

r53updater.json - a file that contains a JSON hash with elements:

id - your Amazon AWS ID

key - your Amazon AWS secret key

domains - a list of domains to check and change

lastIP - placeholder for the last IP value stored, it will be updated

