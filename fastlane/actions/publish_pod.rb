module Fastlane
  module Actions
    module SharedValues
      CHANGES_COMMITTED_FOR_POD_VERSION_UPDATE = :CHANGES_COMMITTED_FOR_POD_VERSION_UPDATE
    end

    class PublishPodAction < Action
      def self.run(params)
        # if validateENVVariables == false
        #   UI.message("ENV variables did not validate for UpdatePodVersionAction to execute. Skipping this action.")
        #   return
        # end
        podspecLocation = findPodspecPath
        if podspecLocation.to_s.empty?
            UI.message("Skipping action as could not find a podspec with a git source")
            return
        end

        # (1) Get podspec Location, tagPrefix, Current Version
        workingDirectory = Actions.lane_context[SharedValues::WORKING_DIRECTORY]

        currentPodspecVersion = getPodspecVersionNumber(podspecLocation)
        # tagPrefix = getTagPrefix(podspecLocation)
        # concatenator = isXSWFramework ? "" : "/"
        expectedTag = currentPodspecVersion #(tagPrefix + concatenator + currentPodspecVersion).strip

        # if the current commit has a tag matching the expectedTag then that means we should not attempt to push a new version
        # if the current commit does not have a tag mathcing the expectedTag that means we should update the build version and podspec version
        # and commit this to the repo.
        # Note: the next execution on CI will see that this new commit would have a tag matching a version number and see that it does not need to do anything
        newVersion = currentPodspecVersion
        if doesCurrentCommitHaveTagMatchingVersion(expectedTag)
          UI.success("No need to make any commits to update version or make a new tag as there is already one present on this commit.")
          if doesAPodSpecVersionAlreadyExistInPodspecRepo(podspecLocation, newVersion)
            UI.success("No need to push a new podspec as a podspec for version (" + newVersion.to_s + ") already exists")
            UI.success("Finshed Execution with no action taken.")
            return
          end
        else
          if doesAPodSpecVersionAlreadyExistInPodspecRepo(podspecLocation, newVersion)
              podspecsLocations = Actions.sh("find " + workingDirectory + "/*.podspec").gsub("//","/").split("\n").each do |location| # replace '//' with '/' incase both working directory comes with trailing '/'
                  UI.message("Possible podspec location at: " + location.to_s)
                  newVersion = bumpCurrentVersion(location) # bump all podspecs so they are on same version
              end
          end
          ensurePlistVersionsAreSameAsNewPodspecVersion(newVersion)
          commitNewVersionToRemote(newVersion: newVersion, additionalFilesToCommit: params[:additionalFilesToCommit])
          tagNewCommitWithUpdatedTag(newVersion) # (tagPrefix + concatenator + newVersion).strip
        end
        pushNewPodspec(podspecLocation)
        # sendSlack(podspecLocation: podspecLocation, newVersion: newVersion)
        UI.success("Finshed updating pod version")
      end

      # get the currect version from the podspec and fail with a user friendly error message if the
      # podspec cannot be located
      def self.getPodspecVersionNumber(podspecLocation)
        currentPodspecVersion = other_action.version_get_podspec(path: podspecLocation)
        UI.important("Current Podspec Version: " + currentPodspecVersion.to_s)
        return currentPodspecVersion
      end

      def self.findPodspecPath
          workingDirectory = Actions.lane_context[SharedValues::WORKING_DIRECTORY]
          podspecsLocations = Actions.sh("find " + workingDirectory + "/*.podspec").gsub("//","/").split("\n").each do |location| # replace '//' with '/' incase both working directory comes with trailing '/'
              UI.message("Examining possible podspec location at: " + location.to_s)
              if doesPodspecHaveGitSource(location)
                  return location
              end
          end
          UI.error("Failed to find podspec with git source to update version and publish new version.")
          return nil
      end

      def self.doesPodspecHaveGitSource(podspecLocation)
          UI.message("Determining if podspec has an git source or not...")
          podspecLines = other_action.read_podspec(path: podspecLocation).to_s.split(",")
          puts podspecLines
          podspecLines.each do |line|
            if line.include? "source"
              UI.important("Source Line in podspec reads: " + line.to_s)
              if line.include? "\"git\"=>"
                  UI.important("Source is from git. Okay to proceed with this action")
                  return true
              else
                  UI.important("Source line found and is not from git. Should not proceed with this action")
              end
            end
          end
          UI.important("Source line is not from git. Should not proceed with this action")
          return false
      end

      # get the tag prefix for the version number used to tag commits
      # if current framework is an XSWFramework return 'v' else
      # proceed with finding the prefix
      def self.getTagPrefix(podspecLocation)
        if isXSWFramework
          return "v"
        end

        podspecLines = other_action.read_podspec(path: podspecLocation).to_s.split(",")
        podspecLines.each do |line|
          if line.include? "\"tag\"=>"
            UI.important("Tag Prefix Line in podspec reads: " + line.to_s)
            tagPrefix = line.gsub("\"tag\"=>\"","").split("/").first
            UI.important("Tag Prefix: (" + tagPrefix.to_s.strip + ")")
            return tagPrefix
          end
        end
        UI.user_error!("Failed to determine Tag Prefix. Cannot safely proceed. Exiting fastlane with failure...")
      end

      # Checks to see if the current commit already has a tag matching the version found in the podspec
      # if it does, the method returns true. It is assumed that this indicates a "re-run" and therefore
      # this action should exit with success otherwise the 2nd run of any commit would always cause a buildID
      # failure.
      def self.doesCurrentCommitHaveTagMatchingVersion(expectedTag)
        UI.message("Looking for expectedTag: (" + expectedTag + ")...")
        gitTags = Actions.sh('git tag', log: false)
        UI.message("Found the following tags on current commit: " + gitTags.to_s.strip)
        if gitTags.include? expectedTag
          UI.success("Commit already has a tag matching tag: ("+expectedTag.to_s+"). "+
          "This execution is assumed to be a re-run... Look like you missed to update podspec new version")
          return true
        end
        UI.important("Commit does not have a tag matching ("+expectedTag.to_s+")")
        return false
      end

      # Checks to see if a tag already exists with same version number found in the podspec on this commit
      # if the tag exists elsewhere on another commit this action should fail as that indicates that this
      # version number is not unique and the user needs to update the podspec and info.plist
      def self.doesTagExist(tagName)
        UI.message("Checking remote for matching tag: (" + tagName.to_s + ")")
        result = Actions.sh("git ls-remote origin " + tagName.to_s)
        if result.to_s.empty?
          UI.message("Did not find tag matching version ("+tagName.to_s+"). Podspec version has been determined to be unique.")
          return false
        end
        UI.message("Found tag matching version ("+tagName.to_s+").")
        return true
      end

      # bumps the current pod spec minor version by 1 and then uses agvtool to set the verion in the info.plist to be the same
      def self.bumpCurrentVersion(podspecLocation)
        bump_type = Actions.lane_context[SharedValues::VERSION_DIGIT_TO_BUMP].to_s
        UI.important("ENV file provided bump_type = " + bump_type)
        UI.important("Bumping the current " + bump_type + " version number by 1")

        currentVersion = other_action.version_get_podspec(path: podspecLocation)
        newVersion = other_action.version_bump_podspec(path: podspecLocation, bump_type: bump_type)
        UI.important("currentVersion: " + currentVersion.to_s + " || newVersion: " + newVersion.to_s)
        return newVersion
      end

      def self.ensurePlistVersionsAreSameAsNewPodspecVersion(newVersion)
        #update info.plists
        Actions.sh("agvtool new-marketing-version " + newVersion)
      end

      # !!!WARNING!!!! This method makes a git commit!! Be very careful calling this method!!
      def self.commitNewVersionToRemote(params)
        newVersion = params[:newVersion]
        additionalFilesToCommit = params[:additionalFilesToCommit]
        UI.message("Additional Files to commit: " + additionalFilesToCommit.to_s)
        UI.important("Committing new version to remote...")
        modifiedFilesToCommitCount = 0
        changedFiles = Actions.sh("git status").split("\n").each do |line|
          if line.include? "modified:"
            modifiedFileName = line.gsub("modified:","").strip
            isModifieldFileWhiteListedForCommit = false
            additionalFilesToCommit.each { |filename|
              UI.message("Checking to see if filename: " + modifiedFileName.to_s + " matches a whitelisted file name: " + filename.to_s)
              if modifiedFileName.include? filename
                UI.message("Modified file ( " + modifiedFileName.to_s + ") matches whitelisted modifiedFileName (" + filename.to_s + "). Will be added to commit")
                isModifieldFileWhiteListedForCommit = true
              end
            }
            if (modifiedFileName.include? ".podspec") || (modifiedFileName.include? ".plist") || (isModifieldFileWhiteListedForCommit)
              UI.important("Will commit modified file: " + modifiedFileName)
              Actions.sh("git add " + modifiedFileName)
              modifiedFilesToCommitCount += 1
            else
              UI.message("Ignoring modified file: " + modifiedFileName)
            end
          end
        end
        if modifiedFilesToCommitCount > 0
          Actions.sh("git commit -m \"Publishing Pod Version: " + newVersion + "\"")
          currentBranchName = Actions.lane_context[SharedValues::CURRENT_BRANCH_NAME]
          Actions.sh("git push --set-upstream origin " + currentBranchName.to_s)
          UI.success("Successfully committed update.")
          Actions.lane_context[SharedValues::CHANGES_COMMITTED_FOR_POD_VERSION_UPDATE] = true
        else
          UI.message("No modified files were found to commit.")
        end
      end

      def self.tagNewCommitWithUpdatedTag(newTag)
        UI.important("Tagging this current commit with tag: (" + newTag.to_s + ").")
        Actions.sh("git tag " + newTag.to_s)
        Actions.sh("git push origin " + newTag.to_s)
        UI.success("Successfully added new tag.")
      end

      def self.doesAPodSpecVersionAlreadyExistInPodspecRepo(podspecLocation, desiredVersion)
        updateLocalAirwatchSpecRepos
        podspecName = podspecLocation.split("/").last.gsub(".podspec","")
        searchResults = getCurrentlyAvailablePodVersions(podspecName)
        UI.message("Checking to see if version: (" + desiredVersion.to_s + ") exists already.")
        searchResults.each { |a|
          if desiredVersion == a.to_s.strip
            UI.important("Found pre-existing pod spec version matching the desired version: ("+ desiredVersion.to_s + ")")
            return true
          end
        }
        UI.important("Did not find pre-existing pod spec version matching the desired version: ("+ desiredVersion.to_s + ")")
        return false
      end

      def self.getCurrentlyAvailablePodVersions(podspecName)
        UI.message("Searching for pod versions of pod named: " + podspecName)
        Actions.sh("pod install") # Needed in case search command fail, Just add pod file in your directory with lib pod 
        searchResults = Actions.sh("pod search " + podspecName + " --simple --no-pager").split("\n")
        availableVersions = []
        if searchResults.count > 0
          searchResults.each do |result|
            if result.include? "Versions:"
              versionArr = result.gsub("- Versions:","").strip.split("[").first
              availableVersions = versionArr.split(",")
              UI.message("Found the following availabe version of pod named: " + podspecName + "\n\t" + availableVersions.to_s)
              return availableVersions
            end
          end
        end
        UI.important("Failed to find any versions of this pod!")
        return availableVersions
      end

      # This method can be added on to support other spec repo's
      # DO NOT UPDATE THE MASTER POD REPO THAT COMES FROM GIT. THAT IS NOT NEEDED FOR THIS ACTION AND WILL TAKE A LONG TIME TO EXECUTE
      def self.updateLocalAirwatchSpecRepos
        UI.message("Updating local copies of awasthi027-ios-spec repos")
        Actions.sh("pod repo update awasthi027-ios-spec --silent || true", log: false)
      end

      def self.pushNewPodspec(podspecLocation)
        UI.message("Appplying Remote user settings......")
        Actions.sh("git config user.name Automated User")
        Actions.sh("git config user.email actions@users.noreply.github.com")
        Actions.sh("git config --unset-all http.https://github.com/.extraheader")

        UI.message("Pushing new podspec...")
        UI.message("USE_STATIC_FRAMEWORKS_FOR_PODSPEC_LINT value: " + Actions.lane_context[SharedValues::USE_STATIC_FRAMEWORKS_FOR_PODSPEC_LINT].to_s)
        command = "pod repo push awasthi027-ios-spec " + podspecLocation + " --allow-warnings --verbose"
        if Actions.lane_context[SharedValues::USE_STATIC_FRAMEWORKS_FOR_PODSPEC_LINT].to_s == "true"
            command = command + " --use-libraries"
        end
        if Actions.lane_context[SharedValues::WORKSPACE_NAME].include? "ADK"
            command = command + " --skip-tests"
        end
        if Actions.lane_context[SharedValues::SKIP_LINT_TESTS].to_s == "true"
            command = command + " --skip-tests"
          end
        Actions.sh(command)

        UI.success("Finished Pushing new podspec")
      end

      # def self.sendSlack(params)
      #   podspecLocation = params[:podspecLocation]
      #   newVersion = params[:newVersion]
      #   #exclude the unit testing metrics
      #   podspecName = podspecLocation.split("/").last.gsub(".podspec","")
      #   Actions.lane_context[SharedValues::TEST_METRICS] = ""
      #   Actions.lane_context[SharedValues::CODE_COVERAGE] = ""
      #   other_action.notify_slack(success:true, messageSubject:"Publishing " + podspecName + " version (" + newVersion.to_s + ")")
      # end

  

      # validate that the current project is a framework and fail with error message if it is not since
      # validate that the current branch is registered as the branch for podspec creation
      # validate that the SSH_REPO_URL has been provided and fails with error message if it has not been provided
      # apps cannot be cocoapods
      def self.validateENVVariables
        if !Actions.lane_context[SharedValues::FRAMEWORK_PROJECT].to_s.downcase.strip == 'true'
          UI.user_error!("This action only supports framework projects. If this project is a framework please"+
          " add/update the FRAMEWORK_PROJECT variable in your .env file to be true.")
          return false
        end
        if Actions.lane_context[SharedValues::SSH_REPO_URL].to_s.empty?
          UI.error("This action cannot successfully execute without the env variable: SSH_REPO_URL. Please provide this variable in your .env file.")
          return false
        end
        return currentBranchIsRegisteredNewPodSpecVersionCreation
      end

      # To prevent new podspec version creations on every single feature branch, the current branch
      # must be registered in order for the new podspec version to be created.
      # This method checks the env value BRANCH_NAME_FOR_POD_CREATION and if current branch
      # is registered it returns true; false otherwise
      def self.currentBranchIsRegisteredNewPodSpecVersionCreation
        if Actions.lane_context[SharedValues::BRANCH_NAME_FOR_POD_CREATION].to_s.empty?
          UI.important("There are no registered branches for new pod version creation. Skipping this step...")
          return false
        end
        branches = Actions.lane_context[SharedValues::BRANCH_NAME_FOR_POD_CREATION].split(",")
        currentBranch = Actions.lane_context[SharedValues::CURRENT_BRANCH_NAME]
        UI.message("Checking to see if currentBranch ("+currentBranch.to_s+") is registered for new pod version creation...")
        branches.each { |registeredBranch|
          if registeredBranch.to_s == currentBranch
            UI.important("Current branch ("+currentBranch.to_s+") is registered for new pod version creation. Matched registeredBranch: (" + registeredBranch.to_s + ")")
            return true
          end
        }
        UI.important("Current branch ("+currentBranch.to_s+") is not registered for new pod version creation.\n\t"+
        "The currently registered branches include: \n\t\t" +branches.to_s)
        return false
      end
      
      # helper method to check if the env variable XSW_FRAMEWORK is present in the env file
      # if not present return false else return true
      def self.isXSWFramework
        if Actions.lane_context[SharedValues::XSW_FRAMEWORK].to_s.empty?
          UI.message("Current framework is not an XSW Module")
          return false
        end

        UI.message("Current framework is an XSW Module")
        return true
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Prepares the updates for a new pod version by tagging or update version if not done"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :additionalFilesToCommit,
                                       env_name: "MODIFIED_FILES_TO_INCLUDE_IN_COMMIT",
                                       description: "Array of file names modified by other actions that should be included in commit",
                                       optional: true,
                                       default_value: [],
                                       is_string:false)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end

