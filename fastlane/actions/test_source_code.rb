module Fastlane
  module Actions
    module SharedValues
    end # end of Shared values

    class TestSourceCodeAction < Action

      def self.run(params)
            UI.important("Test iOS Project")
            testiOSSourceCodeProject
      end # end of  Consturctor
     

      def self.testiOSSourceCodeProject
        
        UI.message("Running Build command.")
        Actions.sh("brew install xcbeautify")
        workspace_File_Name = Actions.lane_context[SharedValues::WORKSPACE_NAME]
        schema_Name = Actions.lane_context[SharedValues::WORKSPACE_SCHEME]
        simulator_Name = Actions.lane_context[SharedValues::SIMULATOR_DEVICE_TYPE]
        ios_Version = Actions.lane_context[SharedValues::SIMULATOR_RUNTIME]

        command = "xcodebuild clean test -workspace " 
        if workspace_File_Name.include? ".xcodeproj"
         command = "xcodebuild clean test -project " 
        end

        projectInfo = workspace_File_Name + " -scheme " + schema_Name 
        simulatorInfo = " -destination " + "\'platform=iOS Simulator,name=" + simulator_Name + ",OS=" + ios_Version + "\'"
        xcbeautify = " | xcbeautify"
        
        command = command + projectInfo + simulatorInfo + xcbeautify

        Actions.sh(command)

        UI.success("Finished project testing")
      end # end of buildiOSSourceCodeProject

      #xcodebuild clean build -workspace UITestPOC.xcworkspace -scheme UITestPOCUITests -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Testing iOS Project"
      end

      def self.details
        "Testing iOS Project====="
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

     end  # end of BuildSourceCodeAction
   end # end of Action
end # Fastlane of fastlane

