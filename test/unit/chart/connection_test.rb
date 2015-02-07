require File.expand_path('../../helper', __FILE__)

class Chart::ConnectionTest < Minitest::Test
  include EnvMethods
  Connection = Chart::Connection

  NULL_ENV = {}
  Connection::ENV_VARIABLES.each_pair do |name, variable|
    NULL_ENV[variable] = nil
  end

  #
  # Connection.options
  #

  def test_options_guesses_default_database_type_and_file
    with_env(NULL_ENV) do
      options = Connection.options
      assert_equal "default", options[:database_type]
      assert_equal "config/database.yml", options[:database_file]
    end
  end
end
