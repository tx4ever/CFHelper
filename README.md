Welcome to the CFHelper Project
=================================
***CLOUDFORMS INTEGRATIONS REPO***  

This project is purposefully created to store CloudForms Automate datastores
that explicitly target specific integrations such as Chef, F5, Infoblox, Bluecat, 
MS AD, NetAPP, etc..) 

Each datastore zip file can be directly imported into an existing CloudForms test/dev 
environment with minimal customization needed for basic functionality.

At import, a namespace will be added directly under the /Integration namespace off the root 
of the domain. The namespace will have the name of the integration target system and 
configured with the supporting classes, instances, and methods.

What's in each datastore zip file?
=====================================================================
Each datastore zip file strictly contains ONLY the components needed to support 
basic use case functionality for a specific system. 

- Namespaces
- Classes
- Instances
- Methods

For example, the *** datastore_chef_070315.zip *** datastore contains only 
the automation elements for a basic Chef integration use case. 

All other namespaces are excluded.

This allows for clean and direct importing into an existing domain for immediate testing. 

More information about each datastore and its supported use case(s) can be 
found in the corresponding readme file.

=====================================================================
Each datastore should contain two domains:

- Domain 1: CompanyABC (Main automation domain with the integration methods)
- Domain 2: CompanyABC_Variables (Reference domain for storing specific variables/attributes)

Import using CloudForms Automate-->import/export tool and then customize as needed.

Happy Automating!!
