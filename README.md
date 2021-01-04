# VM-Series & Azure Virtual WAN Traffic Demo

## Overview 

A terraform build that creates a fully functional environment to demonstrate how the VM-Series can secure Azure Virtual WAN traffic. 


#### Architecture

The build demonstrates two VM-Series traffic flows through a virtual WAN hub. 

1.  **Inbound traffic**:  Dedicated set of VM-Series firewalls that secure internet inbound requests destined to networks connected to a virtual WAN hub.  
    - Additional firewall sets can be added throughout different Azure regions to achieve a globally scalable inbound security edge.
2.  **Outbound traffic**: Dedicated set of VM-Series firewalls that secure lateral traffic traversing through a virtual WAN hub. 
    - This design can be integrated into larger infrastructures that include regional hub and spoke architectures. 


<p align="center">
<img src="https://raw.githubusercontent.com/wwce/azure-tf-virtual-wan/main/images/overview.png" alt="drawing" width="800"/>
</p>

## Prerequisites
 
1.  An active Azure subscription with appropriate permissions and resource allocation quota.
2.  Access to Azure cloud shell. 


## Deployment
#### 1. Download Build
In the Azure Portal, open cloud shell in **Bash mode**.

<p align="center">
<img src="https://raw.githubusercontent.com/wwce/azure-tf-virtual-wan/main/images/step1.png" width="75%" height="75%" >
</p>    

Run the following commands.  Replace *licensing_option* with your preferred licensing type: byol, bundle1, or bundle2. 
```
# Accept VM-Series EULA for desired license type (BYOL, Bundle1, or Bundle2)
$ az vm image terms accept --urn paloaltonetworks:vmseries-flex:<licensing_option>:10.0.3

# Download repository and change directories
$ git clone https://github.com/wwce/azure-tf-virtual-wan; cd azure-tf-virtual-wan
```

#### 2. Edit terraform.tfvars
Open terraform.tfvars and uncomment the **fw_license** variable that matches your licensing option from step 1. 

```
$ vi terraform.tfvars
```

<p align="center">
<b>Your terraform.tfvars should look like this before proceeding</b>
<img src="https://raw.githubusercontent.com/wwce/azure-tf-virtual-wan/main/images/step2.png" width="75%" height="75%" >
</p>      

### 3. Deploy 
Run the following commands to initalize and build the environment.  A total of 104 resources will be created.  Deployment time is approximately 25 minutes. 

```
$ terraform init
$ terraform apply
```


### 4.  Test Inbound <p align="left">
<img src="https://raw.githubusercontent.com/wwce/azure-tf-virtual-wan/main/images/inbound.png" alt="drawing" width="800"/>
</p>
Once the deployment finishes, paste the **SPOKE-INBOUND-HTTP** output value into a web-browser.  The URL is the public load balancer's frontend of the inbound VM-Series firewalls.  Once the VM-Series inspects the traffic, a NAT is applied to send inbound request to the virtual WAN hub.



Next, SSH to the web-server by pasting the SPOKE-INBOUND-SSH output into your existing cloud shell.  This SSH session takes the same path as the previous HTTP path.

### 5.  Test Outbound<p align="left">
<img src="https://raw.githubusercontent.com/wwce/azure-tf-virtual-wan/main/images/outbound.png" alt="drawing" width="800"/>
</p>
After you have logged into the web-server, try to ping/SSH the Ubuntu VM running in the local-spoke VNET (10.3.0.4).  This request will flow through the virtual WAN hub.  The virtual hub routes the traffic to the outbound VM-Series firewalls.  After inspection, the traffic is routed to the locally peered spoke VNET.


## Destroy Environment
Run the following command to destroy the build. 
```
$ terraform destroy
```