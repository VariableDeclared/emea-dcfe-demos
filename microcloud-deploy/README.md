# Single Node Microcloud deployment (Nested VMs)

## Prerequisities

- Single Ubuntu node with LXD installed

## Get started - init lxd - optional if already initialised

```
sudo lxd init --auto
```

## Init tofu

```
sudo snap install --classic opentofu
tofu init
```

## Apply the plan

```
tofu apply
```

## Init Microcloud

The terraform will automatically trigger an initialisation, via the non-interactive method - more information can be found here: https://canonical-microcloud.readthedocs-hosted.com/en/latest/how-to/initialise/#non-interactive-configuration
## TODO:

- Additional networks
~~- Microcloud VM bridging~~
- Multinode
