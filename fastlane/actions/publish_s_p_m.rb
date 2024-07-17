module Fastlane
    module Actions
        class PublishSPMAction < Action
      ##################################################
            # Workspace One SDK Swift Package Helper Methods #
            ##################################################

            def self.run(params)
               # check if branch is eligible to publish to public repo
                unless currentBranchIsRegisteredToPublishToPublicArtifactory
                  UI.message("Skipping manifest publish to public repo...")
                  return
                end

               # setInternalSwiftPackageGITRemoteAndUserInfo
               # checkoutBranchFromInternalRepo # this is required when you want publish on separate repo.
               # setPublicSwiftPackageGITRemoteAndUserInfo # Remote config not required
               # clearContentsFromPublicSwiftPackageRepo # Not required to clear old package file from separate repo
               # addRequiredFilesToPublicSwiftPackageRepo # Add Also not required
               # publishChangesToPublicSwiftPackageRepo # If You uncomment this Below 2 lines not needed
               newTag = getTagVersionFromProject
               createTag(newTag)
            end

            # Checks current branch returns if branch prefix is release returns true else returns false
            def self.currentBranchIsRegisteredToPublishToPublicArtifactory
                currentBranch = Actions.lane_context[SharedValues::CURRENT_BRANCH_NAME]
                UI.message("Checking to see if currentBranch ("+currentBranch.to_s+") is registered to publish manifest to public...")
                prefix = currentBranch.split('-').first
                if prefix.downcase == 'release'.downcase
                    UI.important("Current branch ("+currentBranch.to_s+") is registered for manifest publish")
                  return true
                end
                UI.important("Current branch ("+currentBranch.to_s+") is not registered for manifest publish")
                return false
            end

            # def self.setInternalSwiftPackageGITRemoteAndUserInfo
            #     packageDirectoryPath = Actions.lane_context[SharedValues::SWIFT_PACKAGE_FOLDER_PATH]
            #     # Defaulted to https://stash-iossdk-svc:DFgJJk0LjN87@stash.air-watch.com/scm/isdkl/workspaceonesdk-package.git
            #     swiftPackageTemplateRepositoryOriginURL = Actions.lane_context[SharedValues::SWIFT_PACKAGE_TEMPLATE_REPOSITORY_ORIGIN_URL]
            #     Actions.sh("(cd "+packageDirectoryPath+"; git remote set-url origin " + swiftPackageTemplateRepositoryOriginURL + ")")
            #     Actions.sh("(cd "+packageDirectoryPath+"; git config user.name \"SDK Swift Package Publisher\""+")")
            #     Actions.sh("(cd "+packageDirectoryPath+"; git config user.email \"stash-iossdk-svc@abc.com\""+")")
            # end

            # def self.setPublicSwiftPackageGITRemoteAndUserInfo
            #     packageDirectoryPath = Actions.lane_context[SharedValues::PUBLIC_SPM_REPO_PATH]
            #     packageDirectoryGitURL = Actions.lane_context[SharedValues::PUBLIC_SPM_REPO_GIT_URL]
            #     Actions.sh("(cd "+packageDirectoryPath+"; git remote set-url origin https://abcsdkbot:<PATToken>" + packageDirectoryGitURL + ")")
            #     Actions.sh("(cd "+packageDirectoryPath+"; git config user.name \"ABC SDK Bot Swift Package Publisher\""+")")
            #     Actions.sh("(cd "+packageDirectoryPath+"; git config user.email \"abc@gmail.com\""+")")
            # end       

            # def self.checkoutBranchFromInternalRepo
            #     UI.important('Starting to checkout a branch')
            #     branch_name = Actions.sh('git rev-parse --abbrev-ref HEAD', log: false).gsub("\n",'')
            #     packageDirectoryPath = Actions.lane_context[SharedValues::SWIFT_PACKAGE_FOLDER_PATH]
            #     # cd to package repo directory and checkout/create same branch
            #     Actions.sh("(cd "+packageDirectoryPath+"; ls; git fetch origin; git checkout "+branch_name+"; git status;" +")")
            #     UI.success("checkout Branch = " + branch_name.to_s)
            # end

            # def self.clearContentsFromPublicSwiftPackageRepo
            #     UI.important('Cleaning package repo to add package manifest file.')
            #     packageDirectoryPath = Actions.lane_context[SharedValues::PUBLIC_SPM_REPO_PATH]
            #     # remove if any unwanted files and folder form package
            #     Actions.sh("rm -rf " +packageDirectoryPath+"/.swiftpm")
            #     Actions.sh("rm -rf " +packageDirectoryPath+"/.build")
            #     Actions.sh("rm -f " +packageDirectoryPath+"/Package.swift")
            #     Actions.sh("rm -f " +packageDirectoryPath+"/Acknowledgements.txt")
            #     Actions.sh("rm -f " +packageDirectoryPath+"/README.md")
            #     UI.success("Removed files from Package repo.")
            # end

            # def self.addRequiredFilesToPublicSwiftPackageRepo
            #     packageDirectoryPath = Actions.lane_context[SharedValues::PUBLIC_SPM_REPO_PATH]
            #     internalPackageRepo = Actions.lane_context[SharedValues::SWIFT_PACKAGE_FOLDER_PATH]
            #     internalSDKRepo = Actions.lane_context[SharedValues::WORKING_DIRECTORY]
            #     readmeFileName = Actions.lane_context[SharedValues::PUBLIC_SPM_REPO_README_FILE_NAME]

            #     Actions.sh("cp -a -v "+internalSDKRepo+"/Acknowledgements.txt " + packageDirectoryPath + "/Acknowledgements.txt") #Acknowledgements file
            #     Actions.sh("cp -a -v "+internalSDKRepo+"/" + readmeFileName + " " + packageDirectoryPath + "/README.md") #README file
            #     Actions.sh("cp -a -v "+internalPackageRepo+"/Package.swift " + packageDirectoryPath + "/Package.swift")
            # end

                     # !!!WARNING!!!! This method makes a git commit!! Be very careful calling this method!!
            # def self.publishChangesToPublicSwiftPackageRepo
            #     UI.important('Starting to commit changes to package repo')
            #     packageDirectoryPath = Actions.lane_context[SharedValues::PUBLIC_SPM_REPO_PATH]

            #     branch_name = Actions.sh("(cd "+packageDirectoryPath+"; git rev-parse --abbrev-ref HEAD )", log: false).gsub("\n",'')

            #     filesModifiedToCommit = true
            #     modifiedFiles = Actions.sh("(cd "+packageDirectoryPath+"; git status"+")").split("\n").each do |line|
            #         if line.include? "nothing to commit, working tree clean"
            #             filesModifiedToCommit = false
            #         end
            #     end

            #     if filesModifiedToCommit == true
            #         UI.message("Modified files were found to commit.")

            #         newTag = getTagVersionFromProject

            #         Actions.sh("(cd "+packageDirectoryPath+"; ls; git add -A)")

            #         Actions.sh("(cd "+packageDirectoryPath+"; git commit -m "+"\""+"Publishing New release: "+ newTag+"\"" +" )")
            #         Actions.sh("(cd "+packageDirectoryPath+"; git push origin " +branch_name+")")
            #         UI.success("Successfully committed update.")

            #         tagNewCommitWithUpdatedTag(newTag)
            #     else
            #         UI.message("No modified files were found to commit.")
            #     end
            # end

           def self.getTagVersionFromProject
               target = Actions.lane_context[SharedValues::PROJECT_NAME]
               workingDirectory = Actions.lane_context[SharedValues::WORKING_DIRECTORY]
               pathToXcodeProj = workingDirectory + '/' + target + '.xcodeproj'
               newTag = other_action.get_version_number(xcodeproj: pathToXcodeProj, target: target)
               return newTag
            end

            def self.createTag(newTag)
               UI.important("Tagging this current commit with tag: (" + newTag.to_s + ").")
               Actions.sh("git tag " + newTag.to_s)
               Actions.sh("git push origin " + newTag.to_s)
               UI.success("Successfully added new tag.")
            end
             
            def self.tagNewCommitWithUpdatedTag(newTag)
                UI.important("Tagging this current commit with tag: (" + newTag.to_s + ").")
                packageDirectoryPath = Actions.lane_context[SharedValues::PUBLIC_SPM_REPO_PATH]
                Actions.sh("(cd "+packageDirectoryPath+"; git tag " + newTag.to_s + ")")
                Actions.sh("(cd "+packageDirectoryPath+"; git push origin " + newTag.to_s + ")")
                UI.success("Successfully added new tag.")
            end


            #####################################################
            # @!group Documentation
            #####################################################

            def self.description
                "Updates public swift manifest repo"
            end

            def self.is_supported?(platform)
                [:ios, :mac].include?(platform)
            end
        end
    end
end
