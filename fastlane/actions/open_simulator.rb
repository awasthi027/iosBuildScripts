module Fastlane
  module Actions

    class OpenSimulatorAction < Action
      def self.run(params)
        validateENVVariables
        other_action.close_running_simulators
        other_action.reset_simulator_contents
        openSimulator
      end

      # attempts to creates a simulator with information provided in the .env file
      def self.openSimulator
        simulatorName = Actions.lane_context[SharedValues::SIMULATOR_NAME].gsub(" ","-") # replace any spaces in the name with dashes
        simulatorRuntime = Actions.lane_context[SharedValues::SIMULATOR_RUNTIME].split('-').first(2).join('-')
        deviceType = Actions.lane_context[SharedValues::SIMULATOR_DEVICE_TYPE]
        UI.important("Creating new simulator with name: "+simulatorName+"...")
        udid = Actions.sh("xcrun simctl create "+simulatorName+
            " com.apple.CoreSimulator.SimDeviceType."+deviceType+
            " com.apple.CoreSimulator.SimRuntime.iOS-"+simulatorRuntime).gsub("\n",'') #remove new line character
        Actions.sh("xcrun simctl list devices")
        UI.success('Finshed creating simulator based on variables from the .env file')
      end

      # validate that the ENV variables provided in the .env file are valid and
      # can be used for this action. Fails this actions if they are invalid
      def self.validateENVVariables
        # (1) simulatorName is not empty or nil
        if Actions.lane_context[SharedValues::SIMULATOR_NAME].to_s.empty?
          UI.user_error!("The provided name for the new simulator is nil or empty. Please provide a valid simulator name in the .env file.")
        end
        # (2) deviceType is not empty or nil
        validateDeviceTypeExists
        # (3) validate that the desired simulator runtime exists on this machine
        validateSimRunTimeExists
      end

      # validates that the desired device type actually exists on this machine and
      # fails if it does not exists
      def self.validateDeviceTypeExists
        availableDeviceTypes = []
        deviceTypes = Actions.sh('xcrun simctl list devicetypes', log: false)
        deviceTypes.split(/\n+/).each do | deviceType |
          if deviceType.include? 'SimDeviceType.'
            formattedDeviceType = deviceType.split('SimDeviceType.').last.gsub(")",'').strip
            availableDeviceTypes << formattedDeviceType
          end
        end
        desiredDeviceType = Actions.lane_context[SharedValues::SIMULATOR_DEVICE_TYPE]
        xcodeVersion = Actions.lane_context[SharedValues::XCODE_VERSION]
        if availableDeviceTypes.include? desiredDeviceType
          UI.success("The desired device type (`"+desiredDeviceType.to_s+"`) exists on this machine and is valid for this version of Xcode (`"+xcodeVersion.to_s+")`.")
        else
          UI.user_error!("The desired device type (`"+desiredDeviceType.to_s+"`) does not exist on this machine for this version of Xcode (`"+xcodeVersion.to_s+"`).  Please update your .env file with a valid device type."+ availableOptionsString(title:"Available Device Types", availableOptions:availableDeviceTypes))
        end
      end

      # validates that the desired runtime actually exists on this machine and
      # fails if it does not exists
      def self.validateSimRunTimeExists
        availableRuntimes = []
        runtimes = Actions.sh("xcrun simctl list runtimes", log: false)
        runtimes.split(/\n+/).each do | runtime |
          if runtime.include? 'SimRuntime.iOS'
            formattedRuntime = runtime.split('(').first.gsub(".","-").gsub("iOS",'').strip
            availableRuntimes << formattedRuntime
          end
        end
        desiredRuntime = Actions.lane_context[SharedValues::SIMULATOR_RUNTIME].split('-').first(2).join('-')
        xcodeVersion = Actions.lane_context[SharedValues::XCODE_VERSION]
        if availableRuntimes.include? desiredRuntime
          UI.success("The desired iOS Runtime (`"+desiredRuntime.to_s+"`) exists on this machine. A simulator can be created.")
        else
          UI.user_error!("The desired iOS Runtime (`"+desiredRuntime.to_s+"`) does not exists on this machine for this version of Xcode (`"+xcodeVersion.to_s+"`). Please update your .env file with a valid runtime." + availableOptionsString(title:"Available Runtimes", availableOptions:availableRuntimes))
        end
      end

      # takes in the avaliable options array and a title parameter and prints it in a
      # user friendly messages to let user know what options they can use
      def self.availableOptionsString(params)
        title = params[:title]
        availableOptions = params[:availableOptions]
        outputMessage = "\n\t=== " + title + " ==="
        counter = 0
        availableOptions.each do | runtime |
          counter += 1
          outputMessage = outputMessage + "\n\t   ("+counter.to_s+") " + runtime
        end
        return outputMessage
      end
      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Opens a simulator matching the name provided in the env file"
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
