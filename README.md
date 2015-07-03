Welcome to the CFHelper Project
=================================
***CLOUDFORMS INTEGRATIONS REPO***  

This project is purposefully created to store CloudForms Automate datastores
for a single specific integration system. (Chef, F5, Infoblox, Bluecat, MS AD, NetAPP, etc..) 

Each datastore zip file can be easily imported into a CloudForms test/dev 
environment for basic functionality and customized as needed.

At import, a namespace will be added directly under the /Integration namespace off the root 
of the domain. The namespace will have the name of the integration target system.

What's in each datastore zip file?
=====================================================================
Each datastore zip file strictly contains ONLY the components to needed to support 
basic use case functionality for a specific system. 

- Namespace
- Class(s)
- Instances(s)
- Method(s)

- For example, the *** "datastore_chef_070315.zip"*** datastore contains only 
the automation elements for a basic Chef integration use case. 

- More information about the supported use case(s) can be found in the 
corresponding readme file.

=====================================================================
Each datastore should contain two domains:

- Domain 1: CompanyABC (Main automation domain with the integration methods)
- Domain 2: CompanyABC_Variables (Reference domain for storing specific variables/attributes)

Import using CloudForms automate datastore import tool and then customize as needed.

Happy Integrating!!
