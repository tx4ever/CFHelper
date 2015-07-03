Welcome to the CFHelper Project
=================================
CLOUDFORMS INTEGRATIONS REPO  

This project is purposefully created to store targeted CloudForms Automate Datastores
with specific integration elements. 

Each datastore zip file can be easily imported into a CloudForms test/dev 
environment for the desired integration type.

=====================================================================
Each datastore zip file strictly contains ONLY the automation elements that are needed
to support basic integration for a specific system. 

For example, the datastore_chef_070315 zip file is a datastore export that contains the 
the automate elements for a Chef integration use case:

Chef: 
- Namespaces
- Classes
- Instances
- Methods

More information about the use case the specific datastore supports can be found in the 
corresponding readme file.

=====================================================================

Each datastore should contain two domains:

- Domain 1: CompanyABC (Main automation domain with the integration methods)
- Domain 2: CompanyABC_Variables (Reference domain for storing specific variables/attributes)

Import using CloudForms automate datastore import tool and then customize as needed
