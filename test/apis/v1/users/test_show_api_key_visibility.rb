require_relative "../../../test_helper"

class Test::Apis::V1::Users::TestShowApiKeyVisibility < Minitest::Test
  include ApiUmbrellaTestHelpers::AdminAuth
  include ApiUmbrellaTestHelpers::Setup

  def setup
    super
    setup_server
    ApiUser.where(:registration_source.ne => "seed").delete_all
  end

  def test_new_accounts_they_created_without_roles
    user = FactoryGirl.create(:api_user, :created_at => (Time.now.utc - 2.weeks + 5.minutes), :roles => nil)
    superuser = FactoryGirl.create(:admin)
    limited_admin = FactoryGirl.create(:limited_admin)

    user.update(:created_by => superuser.id)
    assert_api_key_visible(user, superuser)

    user.update(:created_by => limited_admin.id)
    assert_api_key_visible(user, limited_admin)
  end

  def test_new_accounts_they_created_with_roles
    user = FactoryGirl.create(:api_user, :created_at => (Time.now.utc - 2.weeks + 5.minutes), :roles => ["foo"])
    superuser = FactoryGirl.create(:admin)
    limited_admin = FactoryGirl.create(:limited_admin)

    user.update(:created_by => superuser.id)
    assert_api_key_visible(user, superuser)

    user.update(:created_by => limited_admin.id)
    assert_api_key_visible(user, limited_admin)
  end

  def test_old_accounts_they_created_without_roles
    user = FactoryGirl.create(:api_user, :created_at => (Time.now.utc - 2.weeks - 5.minutes), :roles => nil)
    superuser = FactoryGirl.create(:admin)
    limited_admin = FactoryGirl.create(:limited_admin)

    user.update(:created_by => superuser.id)
    assert_api_key_visible(user, superuser)

    user.update(:created_by => limited_admin.id)
    refute_api_key_visible(user, limited_admin)
  end

  def test_old_accounts_they_created_with_roles
    user = FactoryGirl.create(:api_user, :created_at => (Time.now.utc - 2.weeks - 5.minutes), :roles => ["foo"])
    superuser = FactoryGirl.create(:admin)
    limited_admin = FactoryGirl.create(:limited_admin)

    user.update(:created_by => superuser.id)
    assert_api_key_visible(user, superuser)

    user.update(:created_by => limited_admin.id)
    refute_api_key_visible(user, limited_admin)
  end

  def test_new_accounts_other_admins_created_without_roles
    user = FactoryGirl.create(:api_user, :created_by => SecureRandom.uuid, :created_at => (Time.now.utc - 2.weeks + 5.minutes), :roles => nil)
    superuser = FactoryGirl.create(:admin)
    limited_admin = FactoryGirl.create(:limited_admin)

    assert_api_key_visible(user, superuser)
    assert_api_key_visible(user, limited_admin)
  end

  def test_new_accounts_other_admins_created_with_roles
    user = FactoryGirl.create(:api_user, :created_by => SecureRandom.uuid, :created_at => (Time.now.utc - 2.weeks + 5.minutes), :roles => ["foo"])
    superuser = FactoryGirl.create(:admin)
    limited_admin = FactoryGirl.create(:limited_admin)

    assert_api_key_visible(user, superuser)
    refute_api_key_visible(user, limited_admin)
  end

  def test_old_accounts_other_admins_created_without_roles
    user = FactoryGirl.create(:api_user, :created_by => SecureRandom.uuid, :created_at => (Time.now.utc - 2.weeks - 5.minutes), :roles => nil)
    superuser = FactoryGirl.create(:admin)
    limited_admin = FactoryGirl.create(:limited_admin)

    assert_api_key_visible(user, superuser)
    refute_api_key_visible(user, limited_admin)
  end

  def test_old_accounts_other_admins_created_with_roles
    user = FactoryGirl.create(:api_user, :created_by => SecureRandom.uuid, :created_at => (Time.now.utc - 2.weeks - 5.minutes), :roles => ["foo"])
    superuser = FactoryGirl.create(:admin)
    limited_admin = FactoryGirl.create(:limited_admin)

    assert_api_key_visible(user, superuser)
    refute_api_key_visible(user, limited_admin)
  end

  private

  def assert_api_key_visible(user, admin)
    response = Typhoeus.get("https://127.0.0.1:9081/api-umbrella/v1/users/#{user.id}.json", http_options.deep_merge(admin_token(admin)))
    assert_response_code(200, response)

    data = MultiJson.load(response.body)
    assert_equal(user.api_key, data["user"]["api_key"])
    assert_equal((user.created_at.utc + 2.weeks).utc.iso8601, data["user"]["api_key_hides_at"])
    assert_equal("#{user.api_key[0, 6]}...", data["user"]["api_key_preview"])
  end

  def refute_api_key_visible(user, admin)
    response = Typhoeus.get("https://127.0.0.1:9081/api-umbrella/v1/users/#{user.id}.json", http_options.deep_merge(admin_token(admin)))
    assert_response_code(200, response)

    data = MultiJson.load(response.body)
    refute_includes(data["user"].keys, "api_key")
    refute_includes(data["user"].keys, "api_key_hides_at")
    assert_equal("#{user.api_key[0, 6]}...", data["user"]["api_key_preview"])
    refute_match(user.api_key, response.body)
  end
end
