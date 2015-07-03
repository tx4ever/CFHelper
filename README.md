Welcome to the CFHelper Project
=================================
CLOUDFORMS INTEGRATIONS REPO  

This project is purposefully created to store targeted CloudForms Automate Datastores
with specific integration elements. 

Each integration datastore can be easily imported directly into a CloudForms test/dev 
environment for a specific integration type.   

=====================================================================
Each zip file strictly contains ONLY the automation elements to support basic
integration with a given system. 

For example, the datastore_chef_070315 zip file is a datastore export that contains:

Chef: 
- Namespaces
- Classes
- Instances
- Methods

Each datastore should contain two domains:

- Domain 1: CompanyABC (Main automation domain with the integration methods)
- Domain 2: CompanyABC_Variables (Reference domain for storing specific variables/attributes)

Import using CloudForms automate datastore import tool and then customize as needed
