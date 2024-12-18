module Fastlane
  module Actions
    module SharedValues
        # MANDATORY
           WORKSPACE_NAME                                      = :WORKSPACE_NAME #Should include .xcodeproj or .xcworkspace
           WORKSPACE_SCHEME                                    = :WORKSPACE_SCHEME
           DEVELOPER_DIR                                       = :DEVELOPER_DIR
           PROJECT_NAME                                        = :PROJECT_NAME
           SIMULATOR_RUNTIME                                   = :SIMULATOR_RUNTIME
           SIMULATOR_DEVICE_TYPE                               = :SIMULATOR_DEVICE_TYPE  

           # OPTIONAL
           SKIP_LINT_TESTS                                     = :SKIP_LINT_TESTS # skill Test in list
           USE_STATIC_FRAMEWORKS_FOR_PODSPEC_LINT              = :USE_STATIC_FRAMEWORKS_FOR_PODSPEC_LINT
           SIMULATOR_NAME                                      = :SIMULATOR_NAME                        # defaults to {WORKSPACE_SCHEME}Simulator
           SIMULATOR_RUNTIME                                   = :SIMULATOR_RUNTIME                  # defaults to "17-0"
           SIMULATOR_DEVICE_TYPE                               = :SIMULATOR_DEVICE_TYPE          # defaults to "iPhone-14"
           POD_INSTALL_REQUIRED                                = :POD_INSTALL_REQUIRED            # defaults to false
           BRANCH_NAME_FOR_POD_CREATION                        = :BRANCH_NAME_FOR_POD_CREATION # the branch for which new podspec versions will be pushed
           VERSION_DIGIT_TO_BUMP                               = :VERSION_DIGIT_TO_BUMP
           REPO_URL                                            = :REPO_URL  
           SIMULATOR_NAME                                      = :SIMULATOR_NAME
           XCODE_VERSION                                       = :XCODE_VERSION # generated using xcodebuild -version with provided DEVELOPER_DIR
           SCAN_XCARGS                                         = :SCAN_XCARGS

           # GENERIC GENERATED CONSTANTS
           WORKING_DIRECTORY                                   = :WORKING_DIRECTORY
           XSW_FRAMEWORK                                       = :XSW_FRAMEWORK
           GENRIC_MESSAGE                                      = :GENRIC_MESSAGE # It's generic Message 
           DERIVED_DATA_DIRECTORY                              = :DERIVED_DATA_DIRECTORY
           ARTIFACT_OUTPUT_DIRECTORY                           = :ARTIFACT_OUTPUT_DIRECTORY


     end # End of SharedValues


    class DetectEnvironmentInformationAction < Action

        def self.run(params)
            setUniversalConstants
            readMandatoryVariablesFromENVFIle
            readOptionalVariablesFromENVFIle
            # file to file call
            other_action.check_xcode_version_existance
            other_action.get_current_branch_name
             createArtifactOutputDirectory
        end

        # reads in the environment variables from the .env file that are condisidered mandatory
        def self.readMandatoryVariablesFromENVFIle
               UI.important("Reading Mandatory Variables From .env File...")
               Actions.lane_context[SharedValues::WORKSPACE_NAME] = readENVValue(key:'WORKSPACE_NAME', mandatory:true)
               Actions.lane_context[SharedValues::WORKSPACE_SCHEME] = readENVValue(key:'WORKSPACE_SCHEME', mandatory:true)
               Actions.lane_context[SharedValues::DEVELOPER_DIR] = readENVValue(key:'DEVELOPER_DIR', mandatory:true)
               Actions.lane_context[SharedValues::PROJECT_NAME] = readENVValue(key:'PROJECT_NAME', mandatory:true)
               Actions.lane_context[SharedValues::SIMULATOR_RUNTIME] = readENVValue(key:'SIMULATOR_RUNTIME', mandatory:true)
               Actions.lane_context[SharedValues::SIMULATOR_DEVICE_TYPE] = readENVValue(key:'SIMULATOR_DEVICE_TYPE', mandatory:true)
        end # function end readMandatoryVariablesFromENVFIle


        def self.readOptionalVariablesFromENVFIle
              UI.important("Reading optional Variables that have a default Value From .env File...")
             Actions.lane_context[SharedValues::SKIP_LINT_TESTS]                         = readENVValue(key:'SKIP_LINT_TESTS', mandatory:false, defaultValue: false)
             Actions.lane_context[SharedValues::USE_STATIC_FRAMEWORKS_FOR_PODSPEC_LINT]  = readENVValue(key:'USE_STATIC_FRAMEWORKS_FOR_PODSPEC_LINT', mandatory:false, defaultValue: false)
             Actions.lane_context[SharedValues::GENRIC_MESSAGE]                          = readENVValue(key:'GENRIC_MESSAGE', mandatory:false, defaultValue: false)
             Actions.lane_context[SharedValues::XSW_FRAMEWORK]                           = readENVValue(key:'XSW_FRAMEWORK', mandatory:false)
             Actions.lane_context[SharedValues::REPO_URL]                                = readENVValue(key:'REPO_URL', mandatory:false)
             Actions.lane_context[SharedValues::SIMULATOR_NAME]                          = readENVValue(key:'SIMULATOR_NAME', mandatory:false, defaultValue:Actions.lane_context[SharedValues::WORKSPACE_SCHEME].to_s + "Simulator")
             Actions.lane_context[SharedValues::XCODE_VERSION]                           = Actions.sh("xcodebuild -version", log: false).split(/\n+/).first.strip
             Actions.lane_context[SharedValues::SCAN_XCARGS]                             = readENVValue(key:'SCAN_XCARGS', mandatory:false)
             

             Actions.lane_context[SharedValues::DERIVED_DATA_DIRECTORY]                  = Actions.lane_context[SharedValues::WORKING_DIRECTORY] + "/derivedData"
             Actions.lane_context[SharedValues::ARTIFACT_OUTPUT_DIRECTORY]               = Actions.lane_context[SharedValues::WORKING_DIRECTORY] + "/artifacts"


        end # function end readOptionalVariablesFromENVFIle

        def self.createArtifactOutputDirectory 
            Actions.sh("mkdir -p " + Actions.lane_context[SharedValues::DERIVED_DATA_DIRECTORY])
            Actions.sh("mkdir -p " + Actions.lane_context[SharedValues::ARTIFACT_OUTPUT_DIRECTORY])
        end # end Method createArtifactOutputDirectory


        # read value for params[:key] from the .env file
           # if params[:mandatory] is true, fail fastlane execution if value is not found
           # if params[:defaultValue] is provided, the default value will be assigned if value is not found
        def self.readENVValue(params)
             value = ENV[params[:key]]
             UI.message("Reading ENV Value for Key: " + params[:key] + " Value Found: " + value.to_s)
             if value.to_s.empty? #if nil or empty
               if params.has_key?(:defaultValue)
                 value = params[:defaultValue]
                 UI.message("Assigning default value of " + value.to_s + " for Key: " + params[:key])
               end
               if params[:mandatory]
                 UI.user_error!("Mandatory .env value: " + params[:key] + " was not found in .env file")
               end
             end
             return value
        end # function end readENVValue

          # Set shared values that are universal constants and should not need to be changed
        def self.setUniversalConstants
        Actions.lane_context[SharedValues::WORKING_DIRECTORY] = Actions.sh('pwd', log: false).to_s.gsub("\n",'')
        end  # function end setUniversalConstants

        def self.description
         "Reads in environment variables from .env file and adds them to lane_context."
        end

        def self.is_supported?(platform)
         [:ios, :mac].include?(platform)
        end


    end # End of DetectEnvironmentInformationAction

  end # End of Actions
end # End of Fastlane
