module Fastlane
  module Actions

    class SimulatorManagementAction < Action
      def self.run(params)
        Actions.sh("sudo xcrun simctl list devices || true", log: false)
        if doesLaneNeedSimulator(lane: params[:lane])
          validateENVVariables
          UI.header("Step: delete_all_simulators")
          other_action.delete_all_simulators
          UI.header("Step: open_simulator")
          if params[:createNewSim]
            other_action.open_simulator
          else
            UI.important("Skipping creation of a new simulator...")
          end
        else
          UI.important("Skipping simulator management as simulators are not needed for this lane...")
        end
      end

      def self.doesLaneNeedSimulator(params)
        lane = params[:lane]
        return (lane.to_s.include? "unitTest") ||
                (lane.to_s.include? "targetedTesting") ||
                (lane.to_s.include? "debugLane") ||
                (lane.to_s.include? "unitTestWithSonar") ||
                (lane.to_s.include? "thirdPartySDKFrameworks") ||
                (lane.to_s.include? "thirdPartyXamarinCompatibleSDKFrameworks") ||
                (lane.to_s.include? "internalSDKFrameworks") ||
                (lane.to_s.include? "updatePodVersion") ||
                (lane.to_s.include? "updateXSWPodVersion") ||
                (lane.to_s.include? "updateVendoredFrameworkPod") ||
                (lane.to_s.include? "podLibLint") ||
                (lane.to_s.include? "manualPodRepoPush") ||
                (lane.to_s.include? "updateAWCMWrapper") ||
                (lane.to_s.include? "complitationCheckBuildForTesting") ||
                (lane.to_s.include? "deploySITHApplication") ||
                (lane.to_s.include? "simulator")
      end


      def self.validateENVVariables

      end
      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "A short description with <= 80 characters of what this action does"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "You can use this action to do cool things..."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :lane,
                                       env_name: "FL_SIMULATOR_MANAGEMENT_LANE",
                                       description: "The fastlane lane that is executing",
                                       is_string:true),
           FastlaneCore::ConfigItem.new(key: :createNewSim,
                                        env_name: "FL_SIMULATOR_CREATE_NEW",
                                        description: "Should a new simulator be created",
                                        optional: true,
                                        is_string: false,
                                        default_value: true)
        ]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
