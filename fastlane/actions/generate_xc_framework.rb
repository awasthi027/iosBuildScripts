module Fastlane
  module Actions
    module SharedValues
    end # end of Shared values

    class GenerateXcFrameworkAction < Action

      def self.run(params)
            UI.important("Create XC framework at Project Path:")
            schemaName = Actions.lane_context[SharedValues::PROJECT_NAME]
            createiOSXCFramework(schemaName) # create framework
      end # end of  Consturctor
     

      def self.createiOSXCFramework(schema_Name)
      
         UI.message("Start Creating iOS XCFarmework.")
         commandSimulator = "xcodebuild archive" 
         schemaInfo = " -scheme " + schema_Name
         archivePath = " -archivePath ./builds/sim-x86_64-arm64.xcarchive" 
         iphonesimulator = " -sdk iphonesimulator"
         architectureInfo = " -arch arm64 -arch x86_64 SKIP_INSTALL=false BUILD_LIBRARIES_FOR_DISTRIBUTION=true"

         commandSimulator = commandSimulator + schemaInfo + archivePath + iphonesimulator + architectureInfo
        UI.message("Archiving for Apple and Intel simulator Architecture.")
         Actions.sh(commandSimulator, log: false)

         commandDevice = "xcodebuild archive" 
         schemaInfo = " -scheme " + schema_Name
         archivePath = " -archivePath ./builds/ios-arm64.xcarchive"
         iphonesimulator = " -sdk iphoneos"
         architectureInfo = " -arch arm64 SKIP_INSTALL=false BUILD_LIBRARIES_FOR_DISTRIBUTION=true"

         codeSigning = " CODE_SIGN_IDENTITY="""
         codeSigningRequired = " CODE_SIGN_IDENTITY=false"
         codeEntitlement = " CODE_SIGN_ENTITLEMENTS="""
         codeEntitlementAllowed = " CODE_SIGNING_ALLOWED=false"

         commandDevice = commandDevice + schemaInfo + archivePath + iphonesimulator + architectureInfo + codeSigning + codeSigningRequired + codeEntitlement + codeEntitlementAllowed
         UI.message("Archiving for Device Architecture which is same")
         Actions.sh(commandDevice, log: false)

        UI.message("Replaceing - with _ Because command creating framework Like this API_iOS.framework Remove below schema doesn't contain -")
        #schema_Name = Actions.sh("${scheme_name//-/_}") # This can use change Bash

        schema_Name = schema_Name.gsub(/\-/, '_')
        UI.message("Changed Scheme Name: " +   schema_Name)

        simulator_framework_path = "./builds/sim-x86_64-arm64.xcarchive/Products/Library/Frameworks/" + schema_Name + ".framework"
        UI.message("Simulator frameworkPath: " + simulator_framework_path)

        device_framework_path = "./builds/ios-arm64.xcarchive/Products/Library/Frameworks/" + schema_Name + ".framework"
        UI.message("Divice frameworkPath: " + device_framework_path)

        xcframework_path = "./builds/" + schema_Name + ".xcframework"
        
        UI.message("XCframework Path: " + device_framework_path)

        createXCFrameworkCommand = "xcodebuild -create-xcframework -framework " + simulator_framework_path + " -framework " + device_framework_path + " -output " + xcframework_path

        Actions.sh(createXCFrameworkCommand, log: false)
        UI.success(schema_Name + ".framework" + "has been generated at path: " + xcframework_path)

        zipFramework(schema_Name) # Create Zip file from create framework
      end # end of buildiOSSourceCodeProject

      def self.zipFramework(schema_Name)
          UI.success("Start Zipping framework")
          UI.success("Changing dir to create zip file")
          Dir.chdir "builds"
          UI.success("Creating ZIP")
          createZipFileName = " ./" + schema_Name + ".zip"
          zipContentPath = " ./" + schema_Name + ".xcframework"

          createZipFileCommand = "zip -r" + createZipFileName + zipContentPath

          Actions.sh(createZipFileCommand, log: true)
          UI.success("framework zip had been created at path: builds/" + schema_Name + ".zip")
          Actions.sh("cd ..", log: true)
      end 

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Creat XC framework"
      end

      def self.details
        "Creat XC framework====="
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

     end  # end of BuildSourceCodeAction
   end # end of Action
end # Fastlane of fastlane

