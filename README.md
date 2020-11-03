# mailbag
Grab emails and attachments with Ruby

## Update Image
Follow these steps to build a new Docker image.

1. Update mailbag.rb script.
2. Run build.sh to create a new image and push to Artifactory Dev location.
3. Run release.sh to push this new image to Artifactory Prod location.
4. Update Dockerfile in the main directory to point to the new release in Artifactory.
5. Push new code to Bitbucket and open pull request with at least one reviewer.
6. Once merged into master, the new image will be built in OCI Build.

Make sure you look at build.sh and release.sh and update the credentials section if needed.

Remember that merging into master will kick off a new OCI build automatically.
That build will use the new image you created with build.sh and release.sh

### OCI Build Services - DCS detached
https://devops.oci.oraclecorp.com/build/teams/DCS%20Microservices/projects/detached
