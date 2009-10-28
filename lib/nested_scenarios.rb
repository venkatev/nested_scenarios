# Nest multiple scenarios to create a story and defining tests within the nested
# scopes.
#
# Example:
#   scenario :latest_models => true do
#     scenario :sedan => true do
#       add_test 'unlogged in view of latest sedan cars' do
#         get :index
#         assert_redirected_to login_path
#       end
#
#       scenario :viewer => buyer do
#         add_test do
#           get :index
#           assert_response :success
#           # Buyers should not see cars under manufacture
#           assert !assigns(:cars).include(cars(:under_manufacture))
#         end
#       end
#
#       scenario :viewer => car_admin do
#         add_test do
#           get :index
#           assert_response :success
#           # Admin should see cars under manufacture
#           assert assigns(:cars).include(cars(:under_manufacture))
#         end
#       end
#     end
#   end
#
#  generates the following test methods with pre and post scenario codes...
#
#   def test_latest_models_true_and_sedan_true_and_unlogged_in_view_of_latest_sedan_cars
#     # Pre-processing code
#     ....
#     # Post-processing code
#   end
#
#   def test_latest_models_true_and_sedan_true_and_viewer_buyer
#     # Pre-processing code
#     ....
#     # Post-processing code
#   end
#
#  and so on....
#
# The methods <code>scenario_pre_processing</code> and <code>scenario_post_processing</code>
# generate the pre and post scenario code for each test case based on it's scenario
# scope.
#
# This is not restricted to functional tests and can be used with model and other
# unit tests and wherever you want to DRY up the code in the tests.
#
# Vikram Venkatesan (mailto:vikram@chronus.com)
# http://github.com/venkatev/
#
module NestedScenarios
  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
    class << self
      # Map from test name to the scenario configuration for the test.
      class_inheritable_accessor :scenarios_map

      # A temporary map used during scoped method definition. See #scenario
      class_inheritable_accessor :temp_scope

      @@scenarios_map = {}
      @@temp_scope = {}
    end

    # Defines a scenario scope with the given block
    #
    # If <tt>opts[:post]</tt> is specified, it will be used to generate post
    # processing definition for the scenario. See InstanceMethods#scenario_post_processing
    #
    # Params:
    # * <tt>opts</tt> - Hash identifying the scenario
    # * <tt>block</tt> - The Proc that is scoped inside this scenario.
    #
    # Eg.,
    #   scenario :with_money => true do
    #     scenario :in_the_morning => true do
    #       scenario :user => greg do
    #         ....
    #       end
    #     end
    #   end
    #
    def scenario(opts, &block)
      @@temp_scope ||= {}               # Initialize scope if not already done.
      temp_scope_bak = @@temp_scope.dup # Take a copy of the so far scope.
      @@temp_scope.merge!(opts)         # Add this scope's options to +@@temp_scope+
                                        # so that they are available to the nested
                                        # scopes.
      block.call                        # Execute the nested block
      @@temp_scope = temp_scope_bak     # The current scope is over. Revert back
                                        # to previous scope.
    end

    # Defines a test within the scope.
    #
    # Params:
    # * <tt>description</tt> - description of the test case.
    # * <tt>block</tt> - definition of the test, excepting the scenario code
    #   overheads.
    #
    def add_test(test_case = '', &block)
      test_name = ""
      test_name << test_case.gsub(/\s+/,'_') + '_' unless test_case.blank?
      test_name << @@temp_scope.sort_by{|a| a[0].to_s}.collect{|pair| pair.join('_')}.join('_and_')
      test_name.downcase!
      @@scenarios_map[test_name] = @@temp_scope.dup
      self.class_eval do
        define_method('test_' + test_name) do
          scenario_definition = @@scenarios_map[test_name].dup
          post_scenario_definition = scenario_definition.delete(:post) || {}
          scenario_pre_processing(scenario_definition)
          instance_eval(&block)
          scenario_post_processing(post_scenario_definition)
        end
      end
    end
  end

  module InstanceMethods
    # Pre-code to generate for the scenario(s) defined in +scenario_opts+.
    # The code generated will be placed *before* the actual test code passed in
    # the block to <code>add_test</code>.
    #
    # Params:
    # * <tt>scenario_opts</tt> - Hash of scenario definitions.
    #
    def scenario_pre_processing(scenario_opts)
      # This method is just a stub. The test class must provide the implementation.
    end

    # Post-code to generate for the scenario(s) defined in +scenario_opts+.
    # The code generated will be placed *after* the actual test code passed in
    # the block to <code>add_test</code>.
    #
    # Params:
    # * <tt>scenario_opts</tt> - Hash of scenario definitions.
    #
    def scenario_post_processing(scenario_opts)
      # This method is just a stub. The test class must provide the implementation.
    end
  end
end
