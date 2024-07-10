module Fastlane
  module Actions
    module SharedValues
      CURRENT_BRANCH_NAME = :CURRENT_BRANCH_NAME
    end

    class GetCurrentBranchNameAction < Action
      def self.run(params)
        # gets the current branch name replacing '/' characters with '-' characters
        branch_name = Actions.sh('git rev-parse --abbrev-ref HEAD | tr / -', log: false).gsub("\n",'')
        Actions.lane_context[SharedValues::CURRENT_BRANCH_NAME] = branch_name
        UI.success("Current Branch = " + branch_name)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Gets the current branch name replacing '/' characters with '-' characters"
      end

      def self.output
        [
          ['CURRENT_BRANCH_NAME', 'The current git branch with \'-\' replacing \'/\' characters']
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end