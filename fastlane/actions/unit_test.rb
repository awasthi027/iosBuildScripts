module Fastlane
  module Actions
    module SharedValues
      TEST_METRICS = :TEST_METRICS
      CODE_COVERAGE = :CODE_COVERAGE
    end

    class UnitTestAction < Action
      def self.run(params)
        pathToProjectFile = Actions.lane_context[SharedValues::WORKING_DIRECTORY]+"/"+Actions.lane_context[SharedValues::WORKSPACE_NAME]
        if params[:useSonarBuildWrapper]
          testWithSonarBuildWrapper(pathToProjectFile: pathToProjectFile)
        elsif Actions.lane_context[SharedValues::WORKSPACE_NAME].include? ".xcodeproj"
          testProject(pathToProjectFile: pathToProjectFile, buildForTestingOnly: params[:buildForTestingOnly], specificTestClassesToRun: params[:specificTestClassesToRun])
        else
          testWorkspace(pathToProjectFile: pathToProjectFile, buildForTestingOnly: params[:buildForTestingOnly], specificTestClassesToRun: params[:specificTestClassesToRun])
        end
        collectMetricsFromUnitTests
      end

      # wrapper around fastlane's scan action specifying project is a workspace and
      # uses the env varialbes provided.
      def self.testWorkspace(params)
          if params[:specificTestClassesToRun].empty?
              testWorkspaceAllClasses(pathToProjectFile: params[:pathToProjectFile], buildForTestingOnly: params[:buildForTestingOnly])
          else
              testWorkspaceSpecificTestClasses(pathToProjectFile: params[:pathToProjectFile], buildForTestingOnly: params[:buildForTestingOnly], specificTestClassesToRun: params[:specificTestClassesToRun])
          end
      end

      # wrapper around fastlane's scan action specifying project is a workspace and
      # uses the env varialbes provided.
      def self.testProject(params)
          if params[:specificTestClassesToRun].empty?
              testProjectAllClasses(pathToProjectFile: params[:pathToProjectFile], buildForTestingOnly: params[:buildForTestingOnly])
          else
              testProjectSpecificTestClasses(pathToProjectFile: params[:pathToProjectFile], buildForTestingOnly: params[:buildForTestingOnly], specificTestClassesToRun: params[:specificTestClassesToRun])
          end
      end

      # wrapper around fastlane's scan action specifying project is a workspace and
      # uses the env varialbes provided.
      def self.testWorkspaceAllClasses(params)
        other_action.scan(
          workspace: params[:pathToProjectFile],
          scheme: Actions.lane_context[SharedValues::WORKSPACE_SCHEME],
          clean: true,
          code_coverage: true,
          output_types: 'junit',
          output_files: 'junit-report.junit',
          fail_build: true,
          should_zip_build_products: true,
          xcargs: Actions.lane_context[SharedValues::SCAN_XCARGS].to_s,
          result_bundle: true,
          build_for_testing: params[:buildForTestingOnly],
          derived_data_path: Actions.lane_context[SharedValues::DERIVED_DATA_DIRECTORY],
          buildlog_path: Actions.lane_context[SharedValues::ARTIFACT_OUTPUT_DIRECTORY],
          skip_slack:true #slack notifications are sent at end of fastlane execution
        )
      end

      def self.testWorkspaceSpecificTestClasses(params)
        other_action.scan(
          workspace: params[:pathToProjectFile],
          scheme: Actions.lane_context[SharedValues::WORKSPACE_SCHEME],
          clean: true,
          code_coverage: true,
          output_types: 'junit',
          should_zip_build_products: true,
          output_files: 'junit-report.junit',
          fail_build: true,
          only_testing: params[:specificTestClassesToRun],
          xcargs: Actions.lane_context[SharedValues::SCAN_XCARGS].to_s,
          result_bundle: true,
          build_for_testing: params[:buildForTestingOnly],
          derived_data_path: Actions.lane_context[SharedValues::DERIVED_DATA_DIRECTORY],
          buildlog_path: Actions.lane_context[SharedValues::ARTIFACT_OUTPUT_DIRECTORY],
          skip_slack:true #slack notifications are sent at end of fastlane execution
        )
      end

      # wrapper around fastlane's scan action specifying project is a xcodeproj and
      # uses the env varialbes provided.
      def self.testProjectAllClasses(params)
        other_action.scan(
          project: params[:pathToProjectFile],
          scheme: Actions.lane_context[SharedValues::WORKSPACE_SCHEME],
          clean: true,
          code_coverage: true,
          output_types: 'junit',
          output_files: 'junit-report.junit',
          fail_build: true,
          should_zip_build_products: true,
          xcargs: Actions.lane_context[SharedValues::SCAN_XCARGS].to_s,
          result_bundle: true,
          build_for_testing: params[:buildForTestingOnly],
          derived_data_path: Actions.lane_context[SharedValues::DERIVED_DATA_DIRECTORY],
          buildlog_path: Actions.lane_context[SharedValues::ARTIFACT_OUTPUT_DIRECTORY],
          skip_slack:true #slack notifications are sent at end of fastlane execution
        )
      end

      def self.testProjectSpecificTestClasses(params)
        other_action.scan(
          project: params[:pathToProjectFile],
          scheme: Actions.lane_context[SharedValues::WORKSPACE_SCHEME],
          clean: true,
          code_coverage: true,
          output_types: 'junit',
          output_files: 'junit-report.junit',
          fail_build: true,
          should_zip_build_products: true,
          only_testing: params[:specificTestClassesToRun],
          xcargs: Actions.lane_context[SharedValues::SCAN_XCARGS].to_s,
          result_bundle: true,
          build_for_testing: params[:buildForTestingOnly],
          derived_data_path: Actions.lane_context[SharedValues::DERIVED_DATA_DIRECTORY],
          buildlog_path: Actions.lane_context[SharedValues::ARTIFACT_OUTPUT_DIRECTORY],
          skip_slack:true #slack notifications are sent at end of fastlane execution
        )
      end

      # use sonar's build wrapper to wrap around the execution of fastlane's scan action
      def self.testWithSonarBuildWrapper(params)
        UI.message("Attempting to test with sonar build wrapper wrapping execution...")

        build_wrapper_localtion = "~/bamboo-agent-home/xml-data/buildtools/build-wrapper/build-wrapper-macosx-x86"
        derivedDataPath = Actions.lane_context[SharedValues::DERIVED_DATA_DIRECTORY].to_s
        artifactDirectory = Actions.lane_context[SharedValues::ARTIFACT_OUTPUT_DIRECTORY].to_s
        scheme = Actions.lane_context[SharedValues::WORKSPACE_SCHEME]
        project_name = Actions.lane_context[SharedValues::WORKSPACE_NAME]

        if project_name.include? ".xcodeproj"
          Actions.sh(build_wrapper_localtion + " --out-dir " + derivedDataPath +
            "/compilation-database fastlane scan --project \"" + project_name + "\" --scheme \"" + scheme.to_s + "\" --derived_data_path " + derivedDataPath +
            " --buildlog_path " + artifactDirectory + " --skip_slack true --code_coverage true")
        else
          Actions.sh(build_wrapper_localtion + " --out-dir " + derivedDataPath +
            "/compilation-database fastlane scan --workspace \"" + project_name + "\" --scheme \"" + scheme.to_s + "\" --derived_data_path " + derivedDataPath +
            " --buildlog_path " + artifactDirectory + " --skip_slack true --code_coverage true")
        end

        UI.success("Completed testing with sonar build wrapper wrapping execution.")
      end

      # Method to collect unit test metrics and save as SharedValues so other actions can use this information
      # (1) time taken to execute unit tests
      # (2) # of unit tests runs
      # (3) # of unit tests failed
      def self.collectMetricsFromUnitTests
        Dir.glob(Actions.lane_context[SharedValues::ARTIFACT_OUTPUT_DIRECTORY]+"/*.log") { |file|
          UI.message("Logfile found for metrics reporting: " + file)
          executionResults = []
          File.readlines(file).each { |line|
            if line.include? "Executed"
              executionResults << line.strip
            end
          }
          Actions.lane_context[SharedValues::TEST_METRICS] = executionResults.last.to_s
          UI.message("Result Metrics = " + Actions.lane_context[SharedValues::TEST_METRICS])
        }
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

      def self.available_options
        [
         FastlaneCore::ConfigItem.new(key: :useSonarBuildWrapper,
                                      env_name: "FL_USE_SONAR_BUILD_WRAPPER",
                                      description: "useSonarBuildWrapper",
                                      optional: true,
                                      is_string: false,
                                      default_value: false), # the default value if the user didn't provide one
         FastlaneCore::ConfigItem.new(key: :buildForTestingOnly,
                                        env_name: "FL_BUILD_FOR_TESTING_ONLY",
                                        description: "buildForTestingOnly",
                                        optional: true,
                                        is_string: false,
                                        default_value: false), # the default value if the user didn't provide one
         FastlaneCore::ConfigItem.new(key: :specificTestClassesToRun,
                                        env_name: "FL_CLASSES_TO_RUN",
                                        description: "specificClassesToRun",
                                        optional: true,
                                        is_string: false,
                                        default_value: "")
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
