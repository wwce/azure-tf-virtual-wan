# Panorama Orchestration & Azure Virtual WAN
Secure Azure Virtual WAN traffic with Palo Alto Networks VM-Series firewalls.  Please see the [Deployment Guide](https://github.com/wwce/azure-arm-virtual-wan/blob/main/GUIDE.pdf) for more information. 

## Overview 

This Terraform build creates a full demo environment of the VM-Series securing Azure Virtual WAN traffic. 



### Architecture

The build shows two types of traffic flows through a Virtual WAN hub.  

1.  Internet inbound traffic through a VM-Series scale set to directly connected hub virtual network (vwan-spoke)
    - Additional scale sets can be added throughout different Azure regions to achieve a globally scalable inbound security edge.
2.  East-West traffic through a VM-Series scale set from a vwan-spoke to a locally peered virtual network
    - This design can be integrated into larger infrastructures that have regional hub and spoke architectures.  The VM-Series in each regional hub VNET, can secure ingress traffic coming from virtual WAN hubs.
    - This can design can also be applied for traffic between ExpressRoute and VNET connections.


<p align="center">
<img src="https://raw.githubusercontent.com/wwce/azure-arm-virtual-wan/main/images/overview.png" alt="drawing" width="800"/>
</p>

### Prerequisites
 
1.  An active Azure subscription with appropriate permissions and resource allocation quota.
2.  Access to Azure cloud shell. 




  
</br>

## How to Deploy
### 1. Setup & Download Build
In the Azure Portal, open cloud shell in **Bash mode**.

<p align="center">
<img src="hhttps://raw.githubusercontent.com/wwce/azure-tf-virtual-wan/main/images/step1.png" width="75%" height="75%" >
</p>    

Run the following commands.  Replace *licensing_option* with your preferred licensing type: byol, bundle1, or bundle2. 
```
# Accept VM-Series EULA for desired license type (BYOL, Bundle1, or Bundle2)
$ az vm image terms accept --urn paloaltonetworks:vmseries-flex:<licensing_option>:10.0.3

# Download repository and change directories
$ git clone https://github.com/wwce/azure-tf-virtual-wan; cd azure-tf-virtual-wan
```

### 2. Edit terraform.tfvars
Open terraform.tfvars and uncomment the fw_license variable that matches your licensing option from step 1. 

```
$ vi terraform.tfvars
```

<p align="center">
<b>Your terraform.tfvars should look like this before proceeding</b>
<img src="https://raw.githubusercontent.com/wwce/azure-tf-virtual-wan/main/images/step2.png" width="75%" height="75%" >
</p>      

### 3. Deploy Build
```
$ terraform init
$ terraform apply
```

104 resources will be deployed.  


### 4.  Test Inbound Flows


### 5.  Test Lateral Flows
</br>

## How to Destroy
Run the following to destroy the build.
```
$ terraform destroy
```

</br>






**If you do not have the VM-Series deployed, please see [Deployment Guide](https://github.com/wwce/azure-arm-virtual-wan/blob/main/GUIDE.pdf) for how-to.**

</br>

##  Guide

#### <img align="right" width="400" src="https://raw.githubusercontent.com/wwce/azure-arm-virtual-wan/main/images/part1.png"> Part 1:  Create Virtual WAN & Virtual Hub

In this part, a Virtual WAN is created with a virtual hub.  The hub will be used in Parts 2 and 3 to direct traffic from connected spokes to the security VNETs.  If you already have a virtual hub, you can skip this step and proceed to part 2. 
</br>
</br>
</br>
</br>
</br>
</br>
</br>
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fwwce%2Fazure-virtual-wan-connect%2Fmain%2Fpart1_wan.json)
</br>
</br>
</br>

#### <img align="right" width="400" src="https://raw.githubusercontent.com/wwce/azure-arm-virtual-wan/main/images/part2.png"> Part 2:  Connect Inbound VM-Series Scale Set to the Virtual Hub 
Connects an existing security VNET that contains a VM-Series inbound scale set to the virtual hub created in part 1. 
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fwwce%2Fazure-virtual-wan-connect%2Fmain%2Fpart2_connect_inbound.json)
</br>
</br>
</br>

#### <img align="right" width="400" src="https://raw.githubusercontent.com/wwce/azure-arm-virtual-wan/main/images/part3.png"> Part 3:  Connect Outbound VM-Series Scale Set to the Virtual Hub
Connects an existing security VNET that contains a VM-Series outbound scale set to the virtual hub created in part 1.
</br>
</br>
</br>
</br>
</br>
</br>
</br>
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fwwce%2Fazure-virtual-wan-connect%2Fmain%2Fpart3_connect_outbound.json)
</br>
</br>
</br>

#### <img align="right" width="400" src="https://raw.githubusercontent.com/wwce/azure-arm-virtual-wan/main/images/part4.png"> Part 4:  Peer Local VNET to VM-Series Outbound VNET
Creates a spoke VNET that is peered (via vNet Peering) to the outbound VM-Series VNET.  A route table is created to direct all traffic from the spoke VNET to the outbound firewall's interal load balancer.  A route is also added to the virtual hub's route table.  This route will direct virtual WAN traffic destined to the spoke VNET through the outbound VM-Series VNET connection that was created in part 3.   
</br>
</br>
</br>
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fwwce%2Fazure-virtual-wan-connect%2Fmain%2Fpart4_create_peer_spoke.json)
</br>
</br>
</br>

#### <img align="right" width="400" src="https://raw.githubusercontent.com/wwce/azure-arm-virtual-wan/main/images/part5.png"> Part 5:  Connect Spoke VNET to Virtual Hub
Creates a spoke VNET that is directly connected to the virtual hub created in part 1.  This VNET is used to demonstrate/test internet inbound traffic through the inbound VM-Series and also lateral traffic through the outbound VM-Series its local spoke. 
</br>
</br>
</br>
</br>
</br>
</br>
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fwwce%2Fazure-virtual-wan-connect%2Fmain%2Fpart5_create_vhub_spoke.json)

