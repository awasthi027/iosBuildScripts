module Fastlane
  module Actions

    class DeleteAllSimulatorsAction < Action
      def self.run(params)
        # check to make sure the current user is bamboo and if not then
        # do not clear all simulators off this machine
        whoami = Actions.sh("whoami")
        # unless whoami.to_s.include? "bamboo"
        #   UI.important("!!!SKIPPING DELETION OF ALL SIMULATORS AS THIS IS NOT A BUILD MACHINE!!!!")
        #   return
        # else
        #   UI.important("Determined that this is a build machine. Proceeding with the deletion of all simulators...")
        # end

        other_action.close_running_simulators
        simulators = Actions.sh("xcrun simctl list devices || true", log: true).split(/\n+/)
        simulators.each do | simulator |
          if (simulator.include? "(") && (simulator.include? ")")
            deviceUDIDs = simulator
            if simulator.include? "(Shutdown)"
              deviceUDIDs = simulator[0..simulator.index('(Shutdown)')]
            elsif simulator.include? "(Booted)"
              deviceUDIDs = simulator[0..simulator.index('(Booted)')]
            end
            deviceUDIDs = deviceUDIDs.split('(').last.strip.chop
            UI.message("Deleting simulator with UDID: " + deviceUDIDs)

            # UDID's should be longer than 30 characters for the simulators.
            # If it is smaller then that then the above parsing failed for some reason
            puts "DEBUG:: deviceUDIDs = " + deviceUDIDs.to_s + " - deviceUDIDs.to_s.length = " + deviceUDIDs.to_s.length.to_s
            if deviceUDIDs.to_s.length > 30
              Actions.sh("xcrun simctl delete " + deviceUDIDs.to_s + " || true")
            else
              UI.error("Parsing for simulator UDID's failed for some reason.")
              UI.error("Parsed the invalid value of `" + deviceUDIDs.to_s + "` for the simulator UDID.")
              Actions.sh("xcrun simctl list devices || true", log: true)
            end
          end
        end
        UI.success("Finished deleting all installed simulators.")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Deletes all simulators currently installed on this mac"
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
