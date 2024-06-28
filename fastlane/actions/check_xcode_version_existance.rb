module Fastlane
  module Actions

    class CheckXcodeVersionExistanceAction < Action


      def self.run(params)
        UI.important("Checking for the existance of the given developer directory...")
        # (1) does developerDirectory exist on this machine
        if File.exist?(Actions.lane_context[SharedValues::DEVELOPER_DIR])
          # (2) For redundency, run xcode-select even though we have specified DEVELOPER_DIR
          Actions.sh("sudo xcode-select --switch " + Actions.lane_context[SharedValues::DEVELOPER_DIR].to_s)
          # (3) can you run a xcodebuild command
          Actions.sh("xcodebuild -version", log: false, error_callback: lambda { |result|
            UI.error("'xcodebuild -version' command failed.")
            printAvailableXcodeVersions
            return false
          })
          UI.success("DEVELOPER_DIR ("+Actions.lane_context[SharedValues::DEVELOPER_DIR]+") exists on this machine and is usable.")
          return true
        end
        printAvailableXcodeVersions
        return false
      end # end of function constructor


      # searches through the appliocations folder on this machine and prints all
      # xcode's matching the pattern Xcode*.app. The macbuild machine's following the
      # naming convention of Xcode-8.3.3.app, Xcode-9.app
      def self.printAvailableXcodeVersions
          # provided version does not exists. available versions
          xcodeVersions = "--- Available Xcode Versions ---"
          counter = 0
          Dir.glob("/Applications/Xcode*.app") { |appName|
            counter += 1
            xcodeVersions = xcodeVersions + "\n\t("+counter.to_s+") " + appName.gsub("/Applications/",'')
          }
          UI.user_error!("The DEVELOPER_DIR provided in the .env file ("+ Actions.lane_context[SharedValues::DEVELOPER_DIR].to_s + ") does not exists on this machine or could not be located.\n"+
          xcodeVersions)
      end  # end of function printAvailableXcodeVersions

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Checks to see if the xcode version in the lane context exists or not."
      end # end of function description

      def self.details
        "This action will check to see if the xcode version that is given in the lane
        context exists inside this machine's Applications directory and prints
        the available versions if the provide version cannot be found.
        Precondition - Assumes 'SharedValues::DEVELOPER_DIR' exists in the lane context"
      end  # end of function details

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end  # end of function  is_supported
    end
  end
end