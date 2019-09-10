import org.artifactory.exception.CancelException
import org.artifactory.fs.FileLayoutInfo
import org.artifactory.repo.RepoPath
storage {
/**
* Handle before create events.
*
* Closure parameters:
* item
(org.artifactory.fs.ItemInfo) - the original item being created.
*/

beforeCreate { item ->
      log.info("Processing" + item.getName())
      String fileName =
      item.getName()
   
      // Ignore for folders
	  
	  if (!item.isFolder() && fileName != "maven-metadata.xml") {
	  
	     // Ignore for admin users
	     if (!security.currentUser().isAdmin()) {
		 
		    boolean hand_releases = repositories.getRepositoryConfiguration(item.getRepoKey()).isHandleReleases()
			boolean hand_snapshots = repositories.getRepositoryConfiguration(item.getRepoKey()).isHandleSnapshots()
			String packagetype = repositories.getRepositoryConfiguration(item.getRepoKey()).getPackageType()
			
			   if (packagetype == "maven" && hand_releases == true&& hand_snapshots == false) {
			      String repoKey = item.getRepoKey()
				  String path = item.getRepoPath().getName()
				  String artifact = item.getRepoPath().getPath()
				  FileLayoutInfo layout = repositories.getLayoutInfo(item.getRepoPath())
				  String groupId = layout.getOrganization()
				  String artifactId = layout.getModule()
				  String version = layout.getBaseRevision()
				  String classifier = layout.getClassifier()
				  String newrepokey = repoKey + "-ro"
				  log.trace("searching for: $groupId, $artifactId, $version, $classifier in $newrepokey")
				  List<RepoPath> paths = searches.artifactsByGavc(groupId, artifactId, version, classifier, newrepokey)
				  
				       paths.each { RepoPath foundPath ->
					       log.info("Checking for path: " + foundPath)
						   String foundRepoKey = foundPath.getRepoKey()
						   String foundArtifact = foundPath.getPath()
						   log.info("Found ${foundArtifact} for key ${foundRepoKey}")
						   
						   if (newrepokey.equals(foundRepoKey)) {
						      log.info("The repo keys match. Now checking if the artifact is the same...")
							  log.info("Deployed artifact: ${artifact}")
							  log.info("Found artifact: ${foundArtifact}")
							  
							      if (artifact.equals(foundArtifact)) {
								      log.warn("The repoKey and artifact match. We should block deployment here...")
									  throw new CancelException("This artifact already exists in the Read Only repository and cannot be overwritten", 403)
								  }
                                  else {
                                      log.info("Not the same artifact. We can go ahead / check for the next path")
                                  }
								  
                           } else {
                                 log.info("The repokeys don't match. No need to check the artifacts")
                             }
                       }

  				} else {
                      log.info("Nothing to do. Not a maven artifact, or not a releases repo")
                  }

         } else {
              log.info("Skipping check for admin users")
            }

      } else {
          log.info("Nothing to do for folders")
         }

}
}		 
   
   
