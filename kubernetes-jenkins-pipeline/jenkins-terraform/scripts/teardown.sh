#!/bin/bash

juju kill-controller -t 0 openstack-controller
for domain in  Engineering Support Administration; do openstack domain set --disable $domain; done
terraform apply -destroy -auto-apply