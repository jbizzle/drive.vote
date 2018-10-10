# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'devise'
require 'support/controller_macros.rb'
require 'vcr'


# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock # or :fakeweb

  # It's not clear exactly what scheme was used to generate the VCR fixtures, but it appears
  # that it had something to do with a hashing of request.uri -> file name. In any event, it
  # seems that this version of the code, or its runtime, has changed in such a way that renders
  # the hashing incorrect. Instead, we do a one-time scan of all cassette files and map each
  # cassette according to the URLs it contains in its saved HTTP interactions, and then use that
  # map below to test whether we have a cassette
  cassette_files_by_uris = {}
  Dir.chdir(config.cassette_library_dir) do
    Dir.glob("*.yml").each do |file|
      h = File.open(file) { |io| YAML.load io }
      (h["http_interactions"] || []).each do |interaction|
        uri = interaction["request"]["uri"]
        cassette_files_by_uris[uri] = file
      end
    end
  end

  config.around_http_request(lambda { |req| req.uri =~ /maps.googleapis.com/ }) do |request|
    if file = cassette_files_by_uris[request.uri]
      VCR.use_cassette(file, &request)
    else
      request.proceed # Will fail with details about unmatched URI
    end
  end

  config.around_http_request(lambda { |req| req.uri =~ /nominatim.openstreetmap.org/ }) do |request|
    if file = cassette_files_by_uris[request.uri]
      VCR.use_cassette(file, &request)
    else
      request.proceed # Will fail with details about unmatched URI
    end
  end
end

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view

  config.extend ControllerMacros, :type => :controller

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # note we cannot rely on VCR for http calls to timezone b/c it adds a timestamp
  # to every call
  config.before :each do
    allow(Timezone).to receive(:lookup).and_return(nil)
  end
end
