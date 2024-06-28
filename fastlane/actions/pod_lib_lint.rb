module Fastlane
  module Actions
    module SharedValues
      POD_LIB_LINT_CUSTOM_VALUE = :POD_LIB_LINT_CUSTOM_VALUE
    end

    class PodLibLintAction < Action

      def self.run(params)
            workingDirectory = Actions.lane_context[SharedValues::WORKING_DIRECTORY]
             # replace '//' with '/' incase both working directory comes with trailing '/'
             Actions.sh("find " + workingDirectory + "/*.podspec").gsub("//","/").split("\n").each do |location| 

              if doesPodspecHaveArtifactorySource(location)
               UI.important("Attempting to lint a artifactory sourced podpsec...")
              else
              UI.important("Attempting to lint a git sourced podpsec...")
              #moduleName = getPodspeceName(location)
              #replaceAnyPODS_ROOTVariablesWithAbsolutePath(location, moduleName)
              runPodLibLint(location)
              end # end of else
          end # end of Do
      end

     def self.doesPodspecHaveArtifactorySource(location)
          UI.message("Determining if podspec has an artifactory source or not...")
          podspecLines = other_action.read_podspec(path: location).to_s.split(",")
          puts podspecLines
          podspecLines.each do |line|
              if line.include? "source"
                  UI.important("Source Line in podspec reads: " + line.to_s)
                  if line.include? "\"http\"=>\"https://artifactory.air-watch.com/artifactory/"
                      UI.important("Source is artifactory. Should not proceed with this action")
                      return true
                  else
                      UI.important("Source line found and is not artifactory.")
                  end
              end
          end
          UI.important("Source is not artifactory.")
          return false
      end

      def self.runPodLibLint(location)
        UI.message("Running Pod Lib Lint...")
        command = "pod lib lint "+ location +" --allow-warnings --verbose --fail-fast"
        if Actions.lane_context[SharedValues::SKIP_LINT_TESTS].to_s == "true"
            command = command + " --skip-tests"
        end
       UI.message("USE_STATIC_FRAMEWORKS_FOR_PODSPEC_LINT value: " + Actions.lane_context[SharedValues::USE_STATIC_FRAMEWORKS_FOR_PODSPEC_LINT].to_s)
       if Actions.lane_context[SharedValues::USE_STATIC_FRAMEWORKS_FOR_PODSPEC_LINT].to_s == "true"
         command = command + " --use-libraries"
       end
       command = command + " --sources=https://github.com/CocoaPods/Specs"
       Actions.sh(command)
        UI.success("Finished Linting Podspec")
      end
      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Runs pod lib lint on the podspec found in the directory"
      end

      def self.details
        "You can use this action lint your podspec to ensure that they are of valid format and
        to determine if they can be successfully pushed to the pod spec repo"
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
