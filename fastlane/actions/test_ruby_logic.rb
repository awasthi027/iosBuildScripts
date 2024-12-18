module Fastlane
  module Actions
    module SharedValues
      TEST_METRICS = :TEST_METRICS
      CODE_COVERAGE = :CODE_COVERAGE
    end

    class TestRubyLogicAction < Action
      def self.run(params)
          executeTestScan
      end

      def self.executeTestScan
              UI.message("Detecting active device...")
              other_action.scan(project: "CallBackApp.xcodeproj", 
              scheme: "CallBackAppTests", 
             clean: false)
      end
   
      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Runs unit tests."
      end

      def self.details
        "The purpose of this action is to abstract away and simply the decision between
        calling scan with xcworkspace and scan with an xcodeproj."
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
      
    end
  end
end
