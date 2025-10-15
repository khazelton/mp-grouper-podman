=== README.adoc
Goal: created a podman image that sets up midPoint 4.9, Grouper 5, and OpenLDAP with proper shares so that mP can populate LDAP and Grouper can use LDAP as a subject source

==== Steps

1.  Add OpenLDAP to the docker-compose.yml file
2.  Convert to Podman-style images
3.  Integrate the three services
4.  Test and fix

   
