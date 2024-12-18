module Fastlane
  module Actions

    class CloseRunningSimulatorsAction < Action
      def self.run(params)
          UI.message('Closing any currently running Simulators')
          Actions.sh("launchctl remove com.apple.CoreSimulator.CoreSimulatorService || true", log: false)
          Actions.sh("osascript -e \'if application \"Simulator\" is running then\' \
              -e \'    tell app \"Simulator\" to quit\' \
              -e \'end if\' || true", log: false)
          Actions.sh("ps -ef | grep Simulator | grep -v grep | awk '{print $2}' | xargs kill -9 || true", log: false)
          UI.success('Finshed closing currently running Simulators')
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Attemps to close any currently running iOS Simulators."
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
