# output "k8s_addresses" {
#     value = {
#         for k, v in vmware_virtual_machine.k8s_nodes : k => v.id
#     }
# }