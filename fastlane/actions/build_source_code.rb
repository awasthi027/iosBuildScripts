module Fastlane
  module Actions
    module SharedValues
    end # end of Shared values

    class BuildSourceCodeAction < Action

      def self.run(params)
            UI.important("Building iOS Project")
            buildiOSSourceCodeProject
      end # end of  Consturctor
     

      def self.buildiOSSourceCodeProject
        UI.message("Running Build command.")
        project_Name = Actions.lane_context[SharedValues::PROJECT_NAME]
        schema_Name = Actions.lane_context[SharedValues::WORKSPACE_SCHEME]
        simulator_Name = Actions.lane_context[SharedValues::SIMULATOR_DEVICE_TYPE]
        ios_Version = Actions.lane_context[SharedValues::SIMULATOR_RUNTIME]
        command = "xcodebuild clean build -project " 
        projectInfo =  project_Name + ".xcodeproj" +" -scheme " + schema_Name 
        simulatorInfo = " -destination " + "\'platform=iOS Simulator,name=" + simulator_Name + ",OS=" + ios_Version + "\'"
        command = command + projectInfo + simulatorInfo
        Actions.sh(command)
        UI.success("Finished project Building")
      end # end of buildiOSSourceCodeProject

      #xcodebuild clean build -workspace UITestPOC.xcworkspace -scheme UITestPOCUITests -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Build iOS Project"
      end

      def self.details
        "Build iOS Project====="
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

     end  # end of BuildSourceCodeAction
   end # end of Action
end # Fastlane of fastlane

