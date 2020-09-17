# mailbag
Grab emails and attachments with Ruby

## Update Image
Follow these steps to build a new Docker image and then push to Artifactory.

Run build.sh to create the image and push to Artifactory Dev location.
Run release.sh to push this new image to Artifactory Prod location.
Update the Dockerfile in the main directory to point to the new release.

Remember that merging into master will kick off a new OCI build automatically.
That build will use the new image you created with build.sh and release.sh

### OCI Build Services - DCS detached
https://devops.oci.oraclecorp.com/build/teams/DCS%20Microservices/projects/detached
